// Package batch: High-throughput username & identifier collision scanner

///|
pub(all) struct ConfusableGroup {
  skeleton : String
  members : Array[String]
} derive(Debug)

///|
fn group_by_key(
  names : Array[String],
  key : (String) -> String,
) -> Array[ConfusableGroup] {
  let buckets : Map[String, Array[String]] = Map([])
  let order : Array[String] = []
  for name in names {
    let sk = key(name)
    match buckets.get(sk) {
      Some(group) => group.push(name)
      None => {
        let group : Array[String] = [name]
        buckets.set(sk, group)
        order.push(sk)
      }
    }
  }

  let results : Array[ConfusableGroup] = []
  for sk in order {
    if buckets.get(sk) is Some(members) && members.length() > 1 {
      results.push({ skeleton: sk, members, })
    }
  }
  results
}

///|
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup] {
  group_by_key(names, @confusable.skeleton)
}

///|
pub fn find_confusable_groups_ignore_case(
  names : Array[String],
) -> Array[ConfusableGroup] {
  group_by_key(names, @confusable.skeleton_case_folded)
}
