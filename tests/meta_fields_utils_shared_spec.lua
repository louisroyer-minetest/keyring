-- Look for required things in
package.path = "../?.lua;" .. package.path
_G.keyring = {settings = {}, fields = {utils = {}}}
-- Run meta_fields_utils_shared.lua file
require("meta_fields_utils_shared")

-- Tests
describe("shared.is_shared_with", function()
	it("deny", function()
		assert.is_false(keyring.fields.utils.shared.is_shared_with("singleplayer", ""))
		assert.is_false(keyring.fields.utils.shared.is_shared_with("singleplayer",
			"totosingleplayer"))
	end)

	it("allow", function()
		assert.is_true(keyring.fields.utils.shared.is_shared_with("singleplayer",
			"singleplayer"))
		assert.is_true(keyring.fields.utils.shared.is_shared_with("singleplayer",
			"singleplayer toto"))
		assert.is_true(keyring.fields.utils.shared.is_shared_with("singleplayer",
			"toto singleplayer"))
		assert.is_true(keyring.fields.utils.shared.is_shared_with("singleplayer",
			"toto singleplayer tata"))
	end)
end)



describe("shared.remove", function()
	it("removes", function()
		assert.equals("", keyring.fields.utils.shared.remove("singleplayer",
			"singleplayer"))
		assert.equals("toto", keyring.fields.utils.shared.remove("singleplayer",
			"singleplayer toto"))
		assert.equals("toto", keyring.fields.utils.shared.remove("singleplayer",
			"toto singleplayer"))
		assert.equals("tata toto", keyring.fields.utils.shared.remove("singleplayer",
			"singleplayer tata toto"))
		assert.equals("tata toto", keyring.fields.utils.shared.remove("singleplayer",
			"tata toto singleplayer"))
		assert.equals("tata toto", keyring.fields.utils.shared.remove("singleplayer",
			"tata singleplayer toto"))
	end)
end)

describe("shared.get_from_index", function()
	it("index_error", function()
		assert.equals("", keyring.fields.utils.shared.get_from_index(1, ""))
		assert.equals("", keyring.fields.utils.shared.get_from_index(2, ""))
		assert.equals("", keyring.fields.utils.shared.get_from_index(2, "singleplayer"))
		assert.equals("", keyring.fields.utils.shared.get_from_index(3, "singleplayer toto"))
	end)
	it("index_sucess", function()
		assert.equals("singleplayer", keyring.fields.utils.shared.get_from_index(1,
			"singleplayer"))
		assert.equals("singleplayer", keyring.fields.utils.shared.get_from_index(1,
			"singleplayer toto tata"))
		assert.equals("singleplayer", keyring.fields.utils.shared.get_from_index(2,
			"tata singleplayer toto"))
		assert.equals("singleplayer", keyring.fields.utils.shared.get_from_index(3,
			"tata toto singleplayer"))
	end)
end)
