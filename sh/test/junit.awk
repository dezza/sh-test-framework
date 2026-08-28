function fields(start,    text, i) {
  text = $start
  for (i = start + 1; i <= NF; i++)
    text = text FS $i
  return text
}

function xml(text,    result, i, character) {
  result = ""
  for (i = 1; i <= length(text); i++) {
    character = substr(text, i, 1)
    if (character == "&")
      result = result "&amp;"
    else if (character == "<")
      result = result "&lt;"
    else if (character == ">")
      result = result "&gt;"
    else if (character == "\"")
      result = result "&quot;"
    else if (character == "'")
      result = result "&apos;"
    else
      result = result character
  }
  return result
}

function testcase(classname, name, tag, message,    text) {
  text = sprintf("    <testcase classname=\"%s\" name=\"%s\"",
    classname, name)
  if (tag == "")
    return text "/>"

  text = text ">\n"
  text = text sprintf("      <%s message=\"%s\"/>\n", tag, message)
  return text "    </testcase>"
}

$1 == "C" {
  case_name[$2] = fields(3)
  next
}

$1 == "A" {
  classname = xml(case_name[$2])
  name = xml(fields(4))
  tests++
  if ($3 == "fail") {
    failures++
    result[++count] = testcase(classname, name, "failure", "assertion failed")
  } else {
    result[++count] = testcase(classname, name, "", "")
  }
  next
}

$1 == "S" {
  classname = xml(case_name[$2])
  tests++
  skipped++
  result[++count] = testcase(classname, classname, "skipped", xml(fields(3)))
  next
}

$1 == "E" {
  classname = xml(case_name[$2])
  tests++
  failures++
  result[++count] = testcase(classname, classname, "failure",
    "case exited with status " xml($3))
}

END {
  printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  printf "<testsuites tests=\"%d\" failures=\"%d\" skipped=\"%d\">\n", \
    tests, failures, skipped
  printf "  <testsuite name=\"tests\" tests=\"%d\" failures=\"%d\" skipped=\"%d\">\n", \
    tests, failures, skipped

  for (i = 1; i <= count; i++)
    print result[i]

  printf "  </testsuite>\n"
  printf "</testsuites>\n"
}
