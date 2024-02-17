enum SortOptions {
  name,
  mostPlayed,
  recentlyAdded,
}

SortOptions currentSortOption = SortOptions.name;

String getSortOptionDisplayString() {
  switch (currentSortOption) {
    case SortOptions.name:
      return 'Name';
    case SortOptions.mostPlayed:
      return 'Most played';
    case SortOptions.recentlyAdded:
      return 'Recently added';
  }
}
