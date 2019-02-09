proc delete*[T](s: var seq[T], value:T) =
  for i in 0..<s.len:
    if s[i]==value:
      s.delete(i)
      break

