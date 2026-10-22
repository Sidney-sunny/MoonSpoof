import com.ibm.icu.lang.UCharacter;
import com.ibm.icu.lang.UCharacterCategory;
import com.ibm.icu.lang.UProperty;
import com.ibm.icu.lang.UScript;
import com.ibm.icu.text.Bidi;
import com.ibm.icu.text.Normalizer2;
import com.ibm.icu.text.SpoofChecker;
import com.ibm.icu.util.VersionInfo;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.BitSet;
import java.util.Collections;
import java.util.List;

// Standalone optional oracle. Base64 line input avoids a JSON runtime dependency.
public final class IcuReference {
    private static final Normalizer2 NFD = Normalizer2.getNFDInstance();
    private static final SpoofChecker CHECKER = new SpoofChecker.Builder()
        .setChecks(SpoofChecker.MIXED_NUMBERS).build();

    private static String encoded(String value) {
        return "\"" + Base64.getEncoder().encodeToString(value.getBytes(StandardCharsets.UTF_8)) + "\"";
    }

    // Explicit MoonSpoof extensions over ICU's non-bidi getSkeleton operation.
    private static String applicationSkeleton(String input) {
        String current = NFD.normalize(input);
        for (int pass = 0; pass < 32; pass++) {
            StringBuilder widthFolded = new StringBuilder();
            current.codePoints().forEach(cp -> widthFolded.appendCodePoint(
                cp == 0x3000 ? 0x20 : cp >= 0xFF01 && cp <= 0xFF5E ? cp - 0xFEE0 : cp));
            String next = CHECKER.getSkeleton(widthFolded);
            if (next.equals(current)) return next;
            current = next;
        }
        throw new IllegalStateException("Application reference did not converge");
    }

    private static String applicationFolded(String input) {
        String current = input;
        for (int pass = 0; pass < 32; pass++) {
            String next = applicationSkeleton(UCharacter.foldCase(current, true));
            if (next.equals(current)) return next;
            current = next;
        }
        throw new IllegalStateException("Folded reference did not converge");
    }

    private static String properties(int cp) {
        BitSet set = new BitSet();
        UScript.getScriptExtensions(cp, set);
        List<String> names = new ArrayList<>();
        for (int script = set.nextSetBit(0); script >= 0; script = set.nextSetBit(script + 1)) {
            names.add("\"" + UScript.getName(script) + "\"");
        }
        Collections.sort(names);
        int status = UCharacter.getIntPropertyValue(cp, UProperty.IDENTIFIER_STATUS);
        boolean allowed = "Allowed".equals(UCharacter.getPropertyValueName(
            UProperty.IDENTIFIER_STATUS, status, UProperty.NameChoice.LONG));
        int zero = UCharacter.getType(cp) == UCharacterCategory.DECIMAL_DIGIT_NUMBER
            ? cp - UCharacter.getNumericValue(cp) : -1;
        return "[" + cp + ",\"" + UScript.getName(UScript.getScript(cp)) + "\","
            + names + "," + allowed + "," + zero + "]";
    }

    private static void emit(String input) {
        SpoofChecker.CheckResult result = new SpoofChecker.CheckResult();
        CHECKER.failsChecks(input, result);
        List<Integer> zeros = new ArrayList<>();
        for (String digit : result.numerics) zeros.add(digit.codePointAt(0));
        List<String> properties = new ArrayList<>();
        input.codePoints().distinct().forEach(cp -> properties.add(properties(cp)));
        System.out.println("{\"nfd\":" + encoded(NFD.normalize(input))
            + ",\"skeleton\":" + encoded(CHECKER.getSkeleton(input))
            + ",\"foldedSkeleton\":" + encoded(CHECKER.getSkeleton(UCharacter.foldCase(input, true)))
            + ",\"bidiLtrSkeleton\":" + encoded(CHECKER.getBidiSkeleton(Bidi.DIRECTION_LEFT_TO_RIGHT, input))
            + ",\"applicationSkeleton\":" + encoded(applicationSkeleton(input))
            + ",\"applicationFolded\":" + encoded(applicationFolded(input))
            + ",\"decimalSystems\":" + zeros
            + ",\"mixedNumbers\":" + ((result.checks & SpoofChecker.MIXED_NUMBERS) != 0)
            + ",\"properties\":" + properties + "}");
    }

    public static void main(String[] args) throws Exception {
        System.out.println("{\"icu\":\"" + VersionInfo.ICU_VERSION + "\",\"unicode\":\""
            + UCharacter.getUnicodeVersion() + "\",\"java\":\"" + System.getProperty("java.version") + "\"}");
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        for (String line; (line = reader.readLine()) != null;) {
            emit(new String(Base64.getDecoder().decode(line), StandardCharsets.UTF_8));
        }
    }
}
