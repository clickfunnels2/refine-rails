#Sample blueprint

blueprint[0] =
condition_id: "owner_name", #db column
depth: 0,
guide: "123121",
type: "criterion",
value: {
  clause: "contains", #clause
  text: "Francis" #value
}

blueprint[1] =
depth: 0,
index: 1,
type: "conjunction",
word: "and"

blueprint[2]  =
condition_id: "updated_at",
depth: 0,
guid: "12312",
index: 1,
type: "criterion",
value: {
  clause: "less_than",
  values: [3, "ago"]
}