# stdlib_testing

Property-based testing of Gleam's [stdlib](https://github.com/gleam-lang/stdlib).

When writing these tests, I tried not to assume *too* much of the stdlib was already correct; however, sometimes this "rule" is broken to simplify things.

## Progress

Here is a list of functions tested so far, organized by module.  Lists are from `v0.37.0`.

### bit_array

### bool

### bytes_builder

### dict

### dynamic

### float

### function

### int

### io

### iterator

### list

- [ ] all
- [ ] any
- [x] append
- [ ] at
- [x] chunk
- [x] combination_pairs
- [x] combinations
- [x] concat
- [ ] contains
- [ ] drop
- [ ] drop_while
- [ ] each
- [ ] filter
- [ ] filter_map
- [ ] find
- [ ] find_map
- [ ] first
- [ ] flat_map
- [x] flatten
- [ ] fold
- [ ] fold_right
- [ ] fold_until
- [ ] group
- [ ] index_fold
- [ ] index_map
- [ ] interleave
- [ ] intersperse
- [ ] is_empty
- [ ] key_filter
- [ ] key_find
- [ ] key_pop
- [ ] key_set
- [ ] last
- [x] length
- [ ] map
- [ ] map2
- [ ] map_fold
- [ ] new
- [x] partition
- [ ] permutations
- [ ] pop
- [ ] pop_map
- [x] prepend
- [ ] range
- [ ] reduce
- [ ] repeat
- [x] rest
- [x] reverse
- [ ] scan
- [ ] shuffle
- [ ] sized_chunk
- [x] sort
- [x] split
- [ ] split_while
- [ ] strict_zip
- [ ] take
- [ ] take_while
- [x] transpose
- [ ] try_each
- [ ] try_fold
- [ ] try_map
- [x] unique
- [ ] unzip
- [ ] window
- [ ] window_by_2
- [ ] zip

Here is a non-exhaustive list of some of the functions that are assumed to be correct and used to simplify the tests of others in the `list` module.

- dict.fold
- dict.new
- dict.update
- list.flatten
- list.length
- set.from_list
- set.size
- set.to_list

### option

### order

### pair

### queue

### regex

### result

### set

### string

### string_builder

### uri

## qcheck stuff

A big part of this is dogfooding the [qcheck](https://github.com/mooreryan/gleam_qcheck) library.  So, here are some things that I have noticed about that library when writing these tests.

- Some more generators would be nice
  - `list_with_length` -- generate lists of a given length
  - `list_non_empty` -- generate non-empty lists
  - `list_matrix` -- generate a "list of list" style matrix
  - Include edge cases in the int generators (e.g., 0, 1, -1, etc.)
- It would be nice to have some sort of mechanism similar to gleeunit's [should.equal](https://hexdocs.pm/gleeunit/gleeunit/should.html#equal).
  - When a property fails, you do see the original input and shrunk input, but you don't see the result/output of applying those inputs to whatever you are testing.
  - So, when a test fails, if I don't know what the result of that would be, I have to go and add print debugging to see what's going on.  Not ideal.







