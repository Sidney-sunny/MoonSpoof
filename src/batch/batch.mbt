// Package batch: High-throughput username & identifier collision scanner

///|
pub(all) struct ConfusableGroup {
  skeleton : String
  members : Array[String]
} derive(Debug)

///|
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup] {
  let buckets : Map[String, Array[String]] = Map([])
  for name in names {
    let sk = @confusable.skeleton(name)
    match buckets.get(sk) {
      Some(group) => group.push(name)
      None => {
        let group : Array[String] = [name]
        buckets.set(sk, group)
      }
    }
  }

  let results : Array[ConfusableGroup] = []
  for sk, members in buckets {
    if members.length() > 1 {
      results.push({ skeleton: sk, members, })
    }
  }
  results
}

///|
pub fn find_confusable_groups_ignore_case(
  names : Array[String],
) -> Array[ConfusableGroup] {
  let buckets : Map[String, Array[String]] = Map([])
  for name in names {
    let sk = @confusable.skeleton_case_folded(name)
    match buckets.get(sk) {
      Some(group) => group.push(name)
      None => {
        let group : Array[String] = [name]
        buckets.set(sk, group)
      }
    }
  }

  let results : Array[ConfusableGroup] = []
  for sk, members in buckets {
    if members.length() > 1 {
      results.push({ skeleton: sk, members, })
    }
  }
  results
}
