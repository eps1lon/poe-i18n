main -> 
  NoDescription:* Description:* 
  {% ([no_desc, desc]) => ({ no_desc, desc: fromPairs(desc) }) %}

StatIdentifier -> [a-zA-Z0-9_\+\-\%]:+ {% ebnfToString %}
StatIdentifiers -> 
    StatIdentifier {% ident => [ident[0]] %}
  | StatIdentifier " " StatIdentifiers
    {% ([ident, , identifiers]) => [ident, ...identifiers] %}

NoDescription -> 
  "no_description " StatIdentifier  Newline 
  {% ([, id]) => id %}

Description -> 
  DescriptionHeader DescriptionBody Newline:* 
  # if header then header has the identifier, so use this as key
  {% ([header, body]) => [header || body.stats[0], body] %}

DescriptionHeader -> 
  "description" (" " StatIdentifier):? Newline
  {% ([, ident]) => ident ? ident[1] : null %}

DescriptionBody ->
  Stats Translation TranslationLanguage:*
  {% 
    ([stats, english, others]) => ({
      stats,
      languages: fromPairs([['English', english], ...others])
    })
  %}

Stats ->
  Whitespaces IndexNumber " " StatIdentifiers Newline
  {% ([, , , identifiers]) => identifiers %}

TranslationLanguage ->
  Language Newline Translation 
  {% ([language, , translations]) => [language, translations] %}

Translation -> 
  Whitespaces IndexNumber Whitespaces:? Newline Translations
  {% ([, , , , translations]) => translations %}

Language -> 
  Whitespaces:? "lang" Whitespaces StringLiteral 
  {% ([, , ,text]) => text %}

Translations ->
  (Whitespaces TranslationMatcher Newline Blankline:*):+
  {% ([[[, translation]]]) => translation %}

TranslationMatcher -> 
  Matchers Whitespaces StringLiteral OptionalFormatters Whitespaces:?
  {% ([matchers, , text, formatters]) => ({ matchers, text, formatters}) %}

# Formatters
OptionalFormatters -> (" " Formatters):? {% ([matched]) => matched ? matched[1] : [] %}
Formatters -> 
    Formatter
	{% ([formatter]) => [formatter] %}
  | Formatter " " Formatters 
    {% ([formatter, , formatters]) => [formatter, ...formatters] %}
Formatter -> FormatterIdentifier " " FormatterArgument {% ([id, , arg]) => ({ id, arg }) %}
FormatterIdentifier -> [a-zA-Z0-9_]:+ {% ebnfToString %}
FormatterArgument -> (IndexNumber | ReminderIdentifier) {% pipeId %}
ReminderIdentifier -> CamelCase {% id %}
# not actual camelcase but it does the job
CamelCase -> [a-zA-Z]:+ {% ebnfToString %}

# Matching
Matchers -> 
    Matcher
	{% ([matcher]) => [matcher] %}
  | Matcher " " Matchers 
    {% ([matcher, , matchers]) => [matcher, ...matchers] %}
Matcher -> (Bound | RangeBound) {% pipeId %}
Bound -> (Any | Number) {% pipeId %}
RangeBound -> Bound "|" Bound {% ([left, sep, right]) => [left, right] %}
Any -> "#" {% id %}

Number -> 
  ("+" | "-" | null) [0-9]:+ 
  {% ([[sign], digits]) => +`${sign || '+'}${digits.join('')}` %}

StringLiteral -> "\"" [^"]:+ "\"" {% ([, text]) => text.join('') %}

# util
Newline -> "\r\n" {% id %}
Blankline -> Whitespaces:? Newline
Whitespace -> " " | "\t"
Whitespaces -> Whitespace:+ {% ebnfToString %}
IndexNumber -> [0-9]:+ {% (...args) => +ebnfToString(args) %}
 
@{%
  const ebnfToString = ([chars]) => chars.join('');

  // (for  | bar) => [[foo | bar]]
  const pipeId = ([[id]]) => id

  //const fromPairs = pairs => pairs
  const fromPairs = pairs => 
    pairs.reduce((obj, [key, value]) => ({ ...obj, [key]: value }), {})
%}