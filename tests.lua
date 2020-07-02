-- Unit tests
keyring.log("Running tests...")
assert(not keyring.fields.utils.shared.is_shared_with("singleplayer", ""))
assert(keyring.fields.utils.shared.is_shared_with("singleplayer", "singleplayer"))
assert(keyring.fields.utils.shared.is_shared_with("singleplayer", "singleplayer toto"))
assert(keyring.fields.utils.shared.is_shared_with("singleplayer", "toto singleplayer"))
assert(not keyring.fields.utils.shared.is_shared_with("singleplayer", "totosingleplayer"))
assert(keyring.fields.utils.shared.is_shared_with("singleplayer", "toto singleplayer tata"))


assert(keyring.fields.utils.shared.remove("singleplayer", "singleplayer") == "")
assert(keyring.fields.utils.shared.remove("singleplayer", "singleplayer toto") == "toto")
assert(keyring.fields.utils.shared.remove("singleplayer", "toto singleplayer") == "toto")
assert(keyring.fields.utils.shared.remove("singleplayer", "singleplayer tata toto") == "tata toto")
assert(keyring.fields.utils.shared.remove("singleplayer", "tata toto singleplayer") == "tata toto")
assert(keyring.fields.utils.shared.remove("singleplayer", "tata singleplayer toto") == "tata toto")

assert(keyring.fields.utils.shared.get_from_index(1, "") == "")
assert(keyring.fields.utils.shared.get_from_index(2, "") == "")
assert(keyring.fields.utils.shared.get_from_index(1, "singleplayer") == "singleplayer")
assert(keyring.fields.utils.shared.get_from_index(1, "singleplayer toto tata") == "singleplayer")
assert(keyring.fields.utils.shared.get_from_index(2, "tata singleplayer toto") == "singleplayer")
assert(keyring.fields.utils.shared.get_from_index(3, "tata toto singleplayer") == "singleplayer")
assert(keyring.fields.utils.shared.get_from_index(2, "singleplayer") == "")
assert(keyring.fields.utils.shared.get_from_index(3, "singleplayer toto") == "")

keyring.log("Tests OK")
