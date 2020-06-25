# minetest-keyring [![Build Status](https://travis-ci.org/louisroyer/minetest-keyring.svg?branch=master)](https://travis-ci.org/louisroyer/minetest-keyring)
**This is still a Work In Progress**

This minetest mod adds keyrings.
Keyrings can be used to store keys.
Once keys are stored in the keyring, they can be used as a regular keys.

personal keyrings are a variant of keyrings allowing to set access and configuration to keys private.

## Missing features
- [ ] Keyring texture (current is placeholder)
- [ ] Tests on a multiplayer server
- [ ] Screenshot
- [ ] Set version to 1.0 in init.lua
- [ ] Tag a release and upload to contentdb

## Craft
### Keyring
- wire: `basic_materials:gold_wire`/`basic_materials:copper_wire`/`basic_materials:steel_wire`
- key: `default:key`
```text
empty  wire  empty
wire   key   wire
empty  wire  empty
```

or
```text
group:key wire   group:key
wire      empty  wire
group:key wire   group:key
```

This gives back 4 `basic_materials:empty_spool`.
In both crafts, items keys (or `group:key`) items will be added to the resulting keyring.

### personal keyring (shapeless)
- `keyring:keyring`
- `basic_materials:padlock`

### Add a key to the keyring (shapeless)
- `group:key` (`default:key` or `keyring:keyring`)
- `keyring:keyring`/`keyring:personal_keyring`


## Dependencies
- [basic_materials](https://gitlab.com/VanessaE/basic_materials)
- default

<!--![Screenshot](screenshot.png) -->

## License
- CC0-1.0, Louis Royer 2020

## Settings
Setting `keyring.personal_keyring` is available to disable/enable personal keyring (enabled by default).

## Privileges
You can grant the privilege `keyring_inspect` to allow a player to list keys of personal keyrings owned by other players.
