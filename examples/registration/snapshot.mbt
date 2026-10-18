///|
/// Persist the header even for an empty account list.
pub(all) struct Snapshot {
  version : IndexVersion
  records : Array[StoredIdentifier]
} derive(Debug)

///|
pub fn Registry::snapshot(self : Registry) -> Snapshot {
  { version: self.version(), records: self.records(), }
}

///|
/// Reject stale metadata and forged keys; never publish a partially loaded index.
pub fn Registry::restore(
  snapshot : Snapshot,
  key_policy : KeyPolicy,
  validate_syntax~ : (String) -> Result[Unit, String],
  application_policy_version~ : String,
  profile? : @moonspoof.IdentifierProfile = @moonspoof.IdentifierProfile::permissive(),
) -> Result[Registry, String] {
  let index = Registry::new(
    key_policy,
    validate_syntax~,
    application_policy_version~,
    profile~,
  )
  if snapshot.version != index.version() {
    return Err("Index version or policy changed; rebuild from original names")
  }
  for record in snapshot.records {
    if record.version != snapshot.version {
      return Err("Record metadata does not match snapshot header")
    }
    if record.key != index.key(record.name) {
      return Err("Stored key does not match the recomputed key")
    }
    match index.register(record.name) {
      Accepted(_) => ()
      Duplicate(_) => return Err("Snapshot contains a duplicate identifier")
      Collision(_, _) => return Err("Snapshot contains a confusable collision")
      Rejected(_, _) =>
        return Err("Snapshot violates the current application policy")
    }
  }
  Ok(index)
}

///|
/// Revalidate every original name in a new index; return all rejected decisions.
/// The caller replaces its active index only after receiving Ok.
pub fn Registry::rebuild(
  snapshot : Snapshot,
  key_policy : KeyPolicy,
  validate_syntax~ : (String) -> Result[Unit, String],
  application_policy_version~ : String,
  profile? : @moonspoof.IdentifierProfile = @moonspoof.IdentifierProfile::permissive(),
) -> Result[Registry, Array[Decision]] {
  let index = Registry::new(
    key_policy,
    validate_syntax~,
    application_policy_version~,
    profile~,
  )
  let failures : Array[Decision] = []
  for record in snapshot.records {
    match index.register(record.name) {
      Accepted(_) => ()
      failure => failures.push(failure)
    }
  }
  if failures.is_empty() {
    Ok(index)
  } else {
    Err(failures)
  }
}
