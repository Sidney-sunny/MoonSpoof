// Version-pinned canonical normalization shared by all compilation targets.

///|
fn lookup_index(keys : FixedArray[Int], cp : Int) -> Int {
  let mut low = 0
  let mut high = keys.length()
  while low < high {
    let mid = low + (high - low) / 2
    if keys[mid] < cp {
      low = mid + 1
    } else {
      high = mid
    }
  }
  if low < keys.length() && keys[low] == cp {
    low
  } else {
    -1
  }
}

///|
pub fn combining_class(cp : Int) -> Int {
  let index = lookup_index(combining_keys, cp)
  if index < 0 {
    0
  } else {
    combining_values[index]
  }
}

///|
pub fn is_default_ignorable(cp : Int) -> Bool {
  let mut low = 0
  let mut high = ignorable_starts.length()
  while low < high {
    let mid = low + (high - low) / 2
    if ignorable_starts[mid] <= cp {
      low = mid + 1
    } else {
      high = mid
    }
  }
  low > 0 && cp <= ignorable_ends[low - 1]
}

///|
fn write_decomposed(buf : StringBuilder, cp : Int) -> Unit {
  if cp >= 0xAC00 && cp <= 0xD7A3 {
    let index = cp - 0xAC00
    buf.write_char((0x1100 + index / 588).unsafe_to_char())
    buf.write_char((0x1161 + index % 588 / 28).unsafe_to_char())
    if index % 28 != 0 {
      buf.write_char((0x11A7 + index % 28).unsafe_to_char())
    }
  } else {
    let index = lookup_index(decomposition_keys, cp)
    if index < 0 {
      buf.write_char(cp.unsafe_to_char())
    } else {
      buf.write_string(decomposition_values[index])
    }
  }
}

///|
// Stable counting buckets bound reordering cost even for long combining runs.
fn flush_marks(buf : StringBuilder, marks : Array[(Int, Char)]) -> Unit {
  if marks.length() > 0 {
    let buckets : Map[Int, Array[Char]] = Map([])
    let mut minimum = 255
    let mut maximum = 1
    for pair in marks {
      let (cls, ch) = pair
      minimum = if cls < minimum { cls } else { minimum }
      maximum = if cls > maximum { cls } else { maximum }
      match buckets.get(cls) {
        Some(chars) => chars.push(ch)
        None => buckets.set(cls, [ch])
      }
    }
    for cls = minimum; cls <= maximum; cls = cls + 1 {
      if buckets.get(cls) is Some(chars) {
        for ch in chars {
          buf.write_char(ch)
        }
      }
    }
    marks.clear()
  }
}

///|
pub fn normalize_nfd(input : String) -> String {
  let decomposed = StringBuilder()
  for ch in input {
    write_decomposed(decomposed, ch.to_int())
  }
  let buf = StringBuilder()
  let marks : Array[(Int, Char)] = []
  for ch in decomposed.to_string() {
    let cls = combining_class(ch.to_int())
    if cls == 0 {
      flush_marks(buf, marks)
      buf.write_char(ch)
    } else {
      marks.push((cls, ch))
    }
  }
  flush_marks(buf, marks)
  buf.to_string()
}

///|
pub fn case_fold(input : String) -> String {
  let buf = StringBuilder()
  for ch in input {
    let index = lookup_index(casefold_keys, ch.to_int())
    if index < 0 {
      buf.write_char(ch)
    } else {
      buf.write_string(casefold_values[index])
    }
  }
  buf.to_string()
}
