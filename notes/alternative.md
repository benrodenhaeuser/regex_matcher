associate regular language with regex

char => { char }
regex1 | regex2 => M(regex1) union M(regex2)
regex1 regex2 => M(regex1) concat M(regex2)
regex* => { '' } union M(regex) union M(regex*)

The problem is the last rule, which makes this strategy not directly useable for implementation.

Can we split a regex into a first char and a "remainder regex"



match(regex, string) <=> string in M(regex)

compute M on the fly
