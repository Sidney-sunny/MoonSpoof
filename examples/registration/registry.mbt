///|
pub(all) enum KeyPolicy {
  Sensitive
  Folded
} derive(Eq, Debug)

///|
/// Metadata belongs to the index, not just its documentation.
pub(all) struct IndexVersion {
  library_version : String
  unicode_version : String
  key_policy : KeyPolicy
  application_policy_version : String
  profile : @moonspoof.IdentifierProfile
} derive(Eq, Debug)

///|
pub(all) struct StoredIdentifier {
  name : String
  key : String
  version : IndexVersion
} derive(Eq, Debug)

///|
pub(all) enum Decision {
  Accepted(StoredIdentifier)
  Duplicate(StoredIdentifier)
  Collision(StoredIdentifier, @moonspoof.DiagnosticReport)
  Rejected(String, @moonspoof.DiagnosticReport)
} derive(Debug)

///|
/// Single-process reference store; a production database needs atomic enforcement.
pub struct Registry {
  priv version : IndexVersion
  priv validate_syntax : (String) -> Result[Unit, String]
  priv exact : Map[String, StoredIdentifier]
  priv keys : Map[String, StoredIdentifier]
  priv ordered : Array[StoredIdentifier]
}

///|
pub fn Registry::new(
  key_policy : KeyPolicy,
  validate_syntax~ : (String) -> Result[Unit, String],
  application_policy_version~ : String,
  profile? : @moonspoof.IdentifierProfile = @moonspoof.IdentifierProfile::permissive(),
) -> Registry {
  let unicode = @moonspoof.get_unicode_version()
  {
    version: {
      // Keep in sync with moon.mod when copying or upgrading this example.
      library_version: "0.1.0",
      unicode_version: "\{unicode.major}.\{unicode.minor}.\{unicode.update}",
      key_policy,
      application_policy_version,
      profile,
    },
    validate_syntax,
    exact: Map([]),
    keys: Map([]),
    ordered: [],
  }
}

///|
pub fn Registry::version(self : Registry) -> IndexVersion {
  self.version
}

///|
/// Return a copy so callers cannot change the index through its snapshot array.
pub fn Registry::records(self : Registry) -> Array[StoredIdentifier] {
  self.ordered.copy()
}

///|
fn Registry::key(self : Registry, name : String) -> String {
  match self.version.key_policy {
    Sensitive => @moonspoof.skeleton(name)
    Folded => @moonspoof.skeleton_case_folded(name)
  }
}

///|
/// All rejection paths leave the index unchanged.
pub fn Registry::register(self : Registry, name : String) -> Decision {
  match @moonspoof.validate_identifier(name, profile=self.version.profile) {
    Err(reason) => return Rejected(reason, @moonspoof.analyze_identifier(name))
    Ok(_) => ()
  }
  match (self.validate_syntax)(name) {
    Err(reason) => return Rejected(reason, @moonspoof.analyze_identifier(name))
    Ok(_) => ()
  }
  if self.exact.get(name) is Some(existing) {
    return Duplicate(existing)
  }
  let key = self.key(name)
  if self.keys.get(key) is Some(existing) {
    return Collision(existing, @moonspoof.analyze_identifier(name))
  }
  let record = { name, key, version: self.version, }
  self.exact.set(name, record)
  self.keys.set(key, record)
  self.ordered.push(record)
  Accepted(record)
}
