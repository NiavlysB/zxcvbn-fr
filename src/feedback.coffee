scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Utilisez plusieurs mots, évitez les phrases courantes"
      "Pas besoin de caractères spéciaux, chiffres ou lettres majuscules"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Ajoutez un mot ou deux, de préférence des mots peu communs'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Les séries de lettres consécutives sur le clavier sont faciles à deviner'
        else
          'Les courts motifs basés sur le clavier sont faciles à deviner'
        warning: warning
        suggestions: [
          'Utilisez un plus long et plus complexe motif basé sur le clavier'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Les répétitions du type « aaa » sont faciles à deviner'
        else
          'Les répétitions du type « abcabcabc » sont presque aussi faciles à deviner que « abc »'
        warning: warning
        suggestions: [
          'Évitez les répétitions de mots ou de caractères'
        ]

      when 'sequence'
        warning: "Les suites de caractères comme « abc » ou « 6543 » sont faciles à deviner"
        suggestions: [
          'Évitez les suites de caractères'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Les années récentes sont faciles à deviner"
          suggestions: [
            'Évitez les années récentes'
            'Évitez les années en rapport avec vous'
          ]

      when 'date'
        warning: "Les dates sont souvent faciles à deviner"
        suggestions: [
          'Évitez les dates et années en rapport avec vous'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Il s’agit d’un des 10 mots de passe les plus courants'
        else if match.rank <= 100
          'Il s’agit d’un des 100 mots de passe les plus courants'
        else
          'Il s’agit d’un mot de passe très courant'
      else if match.guesses_log10 <= 4
        'Ceci est similaire à un mot de passe fréquemment utilisé'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Un mot seul est facile à deviner'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Les noms et prénoms seuls sont faciles à deviner'
      else
        'Les noms et prénoms communs sont faciles à deviner'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Ajouter des majuscules au début des mots n’aide pas beaucoup"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Un mot tout en majuscules est presque aussi facile à deviner qu’en minuscules"

    if match.reversed and match.token.length >= 4
      suggestions.push "Mettre un mot à l’envers ne le rend pas beaucoup plus difficile à deviner"
    if match.l33t
      suggestions.push "Les substitutions prévisibles comme remplacer « @ » par « a » ne sont pas vraiment efficaces"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
