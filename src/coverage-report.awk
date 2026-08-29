$2 == "percent_covered" {
  print "COVERAGE: " $4 "%"
  found = 1
  exit
}

END {
  if (!found)
    exit 1
}
