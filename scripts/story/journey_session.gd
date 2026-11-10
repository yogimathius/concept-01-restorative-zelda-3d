extends Node
## Carries a journey across scene changes, including test/nonpersistent sessions.
var pending := {}
var persist := true
var save_path := "user://restoration-journey.json"
