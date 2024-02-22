// Save these in config.json or something

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

/// Set this from user settings, default 30s
int lengthLimitMilliseconds = 30000;
