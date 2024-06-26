import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/set
import gleeunit/should
import qcheck/generator as gen
import qcheck/qtest.{given}
import qcheck_gleeunit_utils/test_spec

// list.length
//
// 

pub fn length_function_matches_generated_length__test() {
  use #(l, expected_length) <- given(list_with_length())

  list.length(l) == expected_length
}

// list.sort
//
//

pub fn sorting_matches_oracle__test() {
  use l <- given(list())

  list.sort(l, int.compare) == insertion_sort(l)
}

// list.reverse
//
//

pub fn reverse_is_involutive__test() {
  use l <- given(list())

  list.reverse(list.reverse(l)) == l
}

pub fn reverse_preserves_length__test() {
  use l <- given(list())

  same_length(list.reverse(l), l)
}

pub fn reverse_preserves_elements__test() {
  use l <- given(list())

  same_elements(list.reverse(l), l)
}

pub fn reverse_append__test() {
  use #(a, b) <- given(two_lists())

  list.reverse(list.append(a, b))
  == list.append(list.reverse(b), list.reverse(a))
}

pub fn reverse_concat__test_() {
  // This test will sometimes timeout, so use the `test_spec` to increase the
  // timeout.
  let seconds = 30
  use <- test_spec.make_with_timeout(seconds)
  use #(a, b, c, d) <- given(four_lists())

  // Reversing the concatentation is the same as concatenating reversed lists in
  // opposite order.
  list.reverse(list.concat([a, b, c, d]))
  == list.concat([
    list.reverse(d),
    list.reverse(c),
    list.reverse(b),
    list.reverse(a),
  ])
}

// list.unique
//
//

pub fn unique_works_like_using_a_set__test() {
  use l <- given(list())

  // We use a `set` as an oracle for this.  We must sort the results as the set
  // won't preserve the sorting.

  let actual = list.sort(list.unique(l), int.compare)

  let expected =
    l
    |> set.from_list
    |> set.to_list
    |> list.sort(int.compare)

  actual == expected
}

/// Given that the original list is sorted, if unique changed the order of the
/// elements, then sorting the unique list would yield a different list that
/// the one generated by unique.
pub fn unique_preserves_the_order_of_items__test() {
  [1, 3, 2, 4, 1, 3, 2, 4]
  |> list.unique
  |> should.equal([1, 3, 2, 4])

  [1, 1, 3, 3, 2, 2, 4, 4]
  |> list.unique
  |> should.equal([1, 3, 2, 4])

  use l <- given(sorted_list())
  let unique = list.unique(l)

  sort_list(unique) == unique
}

pub fn there_can_never_be_more_unique_items_than_original_items__test() {
  use l <- given(list())
  list.length(list.unique(l)) <= list.length(l)
}

// list.append & list.split & list.flatten & list.concat
//
//

pub fn list_append__preserves_length__test() {
  use ll <- given(two_lists())
  let #(l1, l2) = ll
  let new_list = list.append(l1, l2)

  list.length(new_list) == list.length(l1) + list.length(l2)
}

pub fn appending_an_empty_list_has_no_effect__test() {
  use l <- given(list())
  list.append([], l) == l && list.append([], l) == l
}

pub fn list_append__preserves_elements_of_both_lists__test() {
  use #(l1, l2) <- given(two_lists())

  let appended_items = count_items(list.append(l1, l2))
  let l1_items = count_items(l1)
  let l2_items = count_items(l2)
  let both_items =
    dict.fold(l1_items, l2_items, fn(d, n, count_a) {
      dict.update(d, n, fn(count_b) {
        case count_b {
          Some(count_b) -> count_a + count_b
          None -> count_a
        }
      })
    })

  appended_items == both_items
}

pub fn splitting_then_appending_round_trips__test() {
  use #(list, index) <- given(non_empty_list_with_index())
  let #(l1, l2) = list.split(list, index)
  list.append(l1, l2) == list
}

pub fn splitting_with_too_big_index_returns_empty_list_second__test() {
  use #(list, length) <- given(list_with_length())
  // Second item should always be empty list.
  let assert #(_, []) = list.split(list, length)
  True
}

pub fn flattening_a_two_el_list_of_lists_is_appending_them__test() {
  use #(l1, l2) <- given(two_lists())

  list.flatten([l1, l2]) == list.append(l1, l2)
}

pub fn empty_lists_dont_affect_flattening__test() {
  use #(l1, l2) <- given(two_lists())
  list.flatten([[], l1, [], [], l2, []]) == list.flatten([l1, l2])
}

pub fn concat_and_flatten_are_the_same__test() {
  // Keep these small to avoid timeouts.
  let list = gen.list_generic(gen.int_uniform(), 0, 5)
  let gen = gen.tuple6(list, list, list, list, list, list)

  use #(l1, l2, l3, l4, l5, l6) <- given(gen)
  let ll = [l1, l2, l3, l4, l5, l6]
  list.flatten(ll) == list.concat(ll)
}

// combinations & combination_pairs
//
//

pub fn combination_pairs_are_unique__test() {
  use l <- given(list())
  let pairs = list.combination_pairs(l)

  let unique_pair_count = set.size(set.from_list(pairs))
  let total_pair_count = list.length(pairs)

  total_pair_count == unique_pair_count
}

// This can get very slow for long lists with large combination sizes, so if you
// change the generator, make sure to keep the sizes small.
pub fn combinations_are_unique__test() {
  let gen =
    gen.int_uniform_inclusive(2, 10)
    |> gen.bind(fn(length) {
      gen.tuple2(
        gen.list_generic(gen.int_uniform(), length, length),
        gen.int_uniform_inclusive(0, length - 1),
      )
    })

  use #(l, n) <- given(gen)
  let pairs = list.combinations(l, n)

  let unique_pair_count = set.size(set.from_list(pairs))
  let total_pair_count = list.length(pairs)

  total_pair_count == unique_pair_count
}

pub fn combination_pairs_length_is_correct__test() {
  use l <- given(gen.list_generic(gen.int_uniform(), 2, 25))
  let pairs = list.combination_pairs(l)

  list.length(pairs) == num_combinations(list.length(l), 2)
}

pub fn combinations_length_is_correct__test() {
  let gen =
    gen.int_uniform_inclusive(2, 10)
    |> gen.bind(fn(length) {
      gen.tuple2(
        gen.list_generic(gen.int_uniform(), length, length),
        gen.int_uniform_inclusive(1, length - 1),
      )
    })

  use #(l, k) <- given(gen)
  let pairs = list.combinations(l, k)

  list.length(pairs) == num_combinations(list.length(l), k)
}

// list.chunk & list.partition
//
// 

pub fn chunk_examples__test() {
  list.chunk([1, 2, 3, 4], fn(x) { x })
  |> should.equal([[1], [2], [3], [4]])

  list.chunk([1, 2, 3, 4], fn(_x) { True })
  |> should.equal([[1, 2, 3, 4]])
}

pub fn returns_one_chunk_for_a_constant_chunking_fn__test() {
  let true_ = fn(_) { True }

  use l <- given(list())

  let result = list.chunk(l, true_)

  list.flatten(result) == l
}

pub fn returns_all_elements_in_own_chunks_with_unique_chunking_fn__test() {
  let itself = fn(x) { x }

  use l <- given(list())

  // Each item should be in its own chunk.
  let expected_length = list.length(l)
  let result = list.chunk(l, itself)

  list.length(result) == expected_length && list.flatten(result) == l
}

pub fn returns_elments_in_correct_order_for_random_function__test() {
  let gen_chunking_fn =
    gen.int_uniform_inclusive(-2, 2)
    |> gen.map(fn(n) { fn(_: Int) -> Int { n } })

  let gen_list =
    gen.list_generic(gen.int_uniform(), min_length: 0, max_length: 100)

  let gen = gen.tuple2(gen_list, gen_chunking_fn)

  use #(l, f) <- given(gen)
  let result = list.chunk(l, f)

  list.flatten(result) == l
}

pub fn partitioning_with_constant_functions_puts_all_elements_in_one_partition__test() {
  use l <- given(gen.list_generic(gen.int_uniform(), 1, 25))

  let assert #(partition, []) = list.partition(l, fn(_) { True })
  let assert True = partition == l

  let assert #([], partition) = list.partition(l, fn(_) { False })
  let assert True = partition == l
}

pub fn partitioning_with_non_constant_functions__test() {
  use l <- given(gen.list_generic(gen.int_uniform(), 1, 25))

  let #(l1, l2) = list.partition(l, int.is_odd)

  list.all(l1, int.is_odd) && list.all(l2, fn(n) { !int.is_odd(n) })
}

pub fn paritioning_keeps_all_original_values__test() {
  use l <- given(gen.list_generic(gen.int_uniform(), 1, 15))
  let #(l1, l2) = list.partition(l, int.is_odd)

  same_elements(list.append(l1, l2), l)
}

// list.transpose
//
//

pub fn transpose_examples__test() {
  list.transpose([[]])
  |> should.equal([])

  list.transpose([[], [], []])
  |> should.equal([])

  [[0, 0]]
  |> list.transpose
  |> list.transpose
  |> should.equal([[0, 0]])
}

pub fn transpose_round_trips_for_non_zero_row_and_col_lengths__test() {
  use m <- given(matrix())

  list.transpose(list.transpose(m)) == m
}

pub fn transpose_swaps_row_and_col_lengths__test() {
  let dim = fn(m) {
    let outer_length = list.length(m)
    let assert [row, ..] = m
    let inner_length = list.length(row)

    #(outer_length, inner_length)
  }

  use m <- given(matrix())

  let #(outer_length, inner_length) = dim(m)
  let #(outer_length_t, inner_length_t) = dim(list.transpose(m))

  outer_length_t == inner_length && inner_length_t == outer_length
}

pub fn transpose_keeps_original_elements__test() {
  use m <- given(matrix())

  same_elements(list.flatten(list.transpose(m)), list.flatten(m))
}

// list.prepend && list.rest
//
//

pub fn prepend_defintion__test() {
  let gen = gen.tuple2(list(), gen.int_uniform())
  use #(l, n) <- given(gen)

  let assert [n2, ..l2] = list.prepend(l, n)

  n2 == n && l2 == l
}

pub fn rest_of_prepended_list_is_the_original_list__test() {
  let gen = gen.tuple2(list(), gen.int_uniform())
  use #(l, n) <- given(gen)

  let assert Ok(result) = list.rest(list.prepend(l, n))
  result == l
}

pub fn prepend_always_increases_length_by_one__test() {
  let gen = gen.tuple2(list(), gen.int_uniform())
  use #(l, n) <- given(gen)

  list.length(list.prepend(l, n)) == list.length(l) + 1
}

// list.contains

pub fn contains_is_always_false_for_empty_lists__test() {
  use n <- given(gen.int_uniform())
  !list.contains([], n)
}

pub fn a_list_always_contains_the_inserted_element__test() {
  let gen = gen.tuple2(non_empty_list_with_index(), gen.int_uniform())

  use #(#(l, i), n) <- given(gen)

  let #(l1, l2) = list.split(l, i)
  let l = list.concat([l1, [n], l2])
  list.contains(l, n)
}

pub fn concat_doesnt_change_result_of_contains__test() {
  let gen =
    gen.tuple3(
      gen.list_generic(gen.int_uniform(), 0, 10),
      gen.list_generic(gen.int_uniform(), 0, 10),
      gen.int_uniform(),
    )

  use #(l1, l2, n) <- given(gen)

  let l2 = [n, ..l2]
  let assert True = list.contains(l2, n)

  list.contains(list.append(l1, l2), n)
}

// list.drop

pub fn if_n_is_gte_length_then_drop_returns_empty_list__test() {
  let gen = gen.tuple2(list_with_length(), gen.int_uniform())
  use #(#(l, len), i) <- given(gen)

  let assert [] = list.drop(l, len + int.absolute_value(i))
  True
}

pub fn for_in_bounds_n_drop_always_drops_n_items__test() {
  let gen = {
    use #(l, len) <- gen.bind(non_empty_list_with_length())
    gen.tuple3(
      gen.return(l),
      gen.return(len),
      gen.int_uniform_inclusive(0, len - 1),
    )
  }

  use #(l, original_length, n) <- given(gen)
  let l2 = list.drop(l, n)
  list.length(l2) + n == original_length
}

pub fn dropping_zero_items_returns_original_list__test() {
  use l <- given(list())
  list.drop(l, 0) == l
}

pub fn remaining_elements_after_drop_match_second_half_of_split__test() {
  use #(l, i) <- qtest.given(non_empty_list_with_index())
  let l1 = list.drop(l, i)
  let #(_, l2) = list.split(l, i)
  l1 == l2
}

// utils
//
// 

// generate a list of ints
fn list() {
  gen.int_uniform()
  |> gen.list_generic(0, 20)
}

fn sorted_list() {
  gen.map(list(), sort_list)
}

/// Generate a list along with an index that is guaranteed to be in bounds.
fn non_empty_list_with_index() {
  gen.small_strictly_positive_int()
  |> gen.bind(fn(length) {
    gen.tuple2(
      gen.list_generic(gen.int_uniform(), length, length),
      gen.int_uniform_inclusive(0, length - 1),
    )
  })
}

fn list_with_length() {
  gen.small_positive_or_zero_int()
  |> gen.bind(fn(length) {
    gen.tuple2(
      gen.list_generic(gen.int_uniform(), length, length),
      gen.return(length),
    )
  })
}

fn non_empty_list_with_length() {
  gen.small_strictly_positive_int()
  |> gen.bind(fn(length) {
    gen.tuple2(
      gen.list_generic(gen.int_uniform(), length, length),
      gen.return(length),
    )
  })
}

fn two_lists() {
  gen.tuple2(list(), list())
}

fn four_lists() {
  gen.tuple4(list(), list(), list(), list())
}

fn matrix() -> gen.Generator(List(List(Int))) {
  let row_length_generator = gen.int_uniform_inclusive(1, 7)

  row_length_generator
  |> gen.bind(fn(row_length) {
    let row_generator =
      gen.list_generic(gen.int_uniform(), row_length, row_length)
    gen.list_generic(row_generator, 1, 7)
  })
}

// Calculate the numeber of combinations.
//
// This should be well behaved when n is within the small sizes we are
// generating.
fn num_combinations(n: Int, k: Int) -> Int {
  case int.compare(n, k) {
    Gt -> {
      let numerator =
        list.range(int.max(k, n - k) + 1, n)
        |> list.fold(1, int.multiply)

      let denominator =
        list.range(1, int.min(k, n - k))
        |> list.fold(1, int.multiply)

      numerator / denominator
    }
    Eq -> 1
    Lt -> panic as "num_combinations: expected n >= k"
  }
}

// insertion sort for test oracle

fn insert(l, x) {
  case l {
    [y, ..ys] if x > y -> [y, ..insert(ys, x)]
    _ -> [x, ..l]
  }
}

// Used as an oracle to test `list.sort`.
fn insertion_sort(l) {
  list.fold(l, [], insert)
}

// Stdlib list sorting specialized for `Int`.
fn sort_list(l: List(Int)) -> List(Int) {
  list.sort(l, int.compare)
}

// general properties and their helpers

fn same_length(a: List(a), b: List(b)) -> Bool {
  list.length(a) == list.length(b)
}

fn inc(x) {
  case x {
    Some(n) -> n + 1
    None -> 1
  }
}

fn count_items(l: List(a)) -> Dict(a, Int) {
  list.fold(l, dict.new(), fn(d, n) { dict.update(d, n, inc) })
}

fn same_elements(l1: List(a), l2: List(a)) -> Bool {
  let d1 = count_items(l1)
  let d2 = count_items(l2)

  d1 == d2
}
