/// Function to reduce an array of bytes to an n-bytes integer.
///
/// The array is assumed to be in little-endian order.
/// The function is meant to be used by [Collection.reducedIndexed] provided by
/// the `dart:collections` package.
///
/// The function creates an integer by concating the bytes of the array
/// by shifting each byte to the left depending on the index of the byte.
int intReducer(int idx, int prev, int byte) => prev | byte << (8 * idx);
