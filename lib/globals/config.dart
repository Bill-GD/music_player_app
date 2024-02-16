enum SongSorting {
  name,
  mostPlayed,
  recentlyAdded,
}

SongSorting currentSortType = SongSorting.name;

String getSortOptionDisplayString() {
  switch (currentSortType) {
    case SongSorting.name:
      return 'Name';
    case SongSorting.mostPlayed:
      return 'Most played';
    case SongSorting.recentlyAdded:
      return 'Recently added';
  }
}