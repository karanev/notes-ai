import './nlp_models.dart';

class IntentRecognizer {
  // --- Keyword Lists for Intent Recognition ---
  static const List<String> _countPhrases = ['how many', 'count', 'number of', 'quantity of'];
  static const List<String> _listPhrases = ['show me', 'show my', 'show the', 'show all', 'list my', 'list the', 'list all', 'list', 'find my', 'find the', 'find all', 'find', 'get my', 'get the', 'get all', 'get', 'what are my', 'what are the', 'display my', 'display the', 'display all', 'display', 'tell me about my', 'tell me about the', 'fetch', 'retrieve'];
  static const List<String> _createPhrases = ['create a', 'create new', 'create', 'add a', 'add new', 'add', 'make a', 'make new', 'make', 'new', 'draft a', 'draft', 'write a', 'write', 'set up', 'schedule a', 'schedule'];
  static const List<String> _objectKeywords = ['note', 'task', 'todo', 'reminder', 'item', 'entry', 'list'];
  static const List<String> _statusKeywords = ['unfinished', 'pending', 'completed', 'done', 'active'];
  static const List<String> _generalCreateVerbs = ['add', 'create', 'make', 'schedule', 'set up', 'draft', 'write'];
  static const List<String> _listQueryContextKeywords = ['my', 'the', 'all', 'me'];

  // Helper to check if the query contains a specific phrase (as whole words)
  bool _queryContainsPhrase(String phrase, String query) {
    return RegExp(r'\b' + RegExp.escape(phrase) + r'\b').hasMatch(query);
  }

  // Helper to check if the query starts with a specific phrase (ensuring it's a whole word/phrase at start)
  bool _queryStartsWithPhrase(String phrase, String query) {
    return RegExp(r'^' + RegExp.escape(phrase) + r'\b').hasMatch(query);
  }

  bool _checkCountIntent(String query) {
    for (final phrase in _countPhrases) {
      if (_queryContainsPhrase(phrase, query)) {
        final hasObject = _objectKeywords.any((obj) => _queryContainsPhrase(obj, query));
        final hasStatus = _statusKeywords.any((status) => _queryContainsPhrase(status, query));
        if (hasObject || hasStatus) {
          return true;
        }
        if (phrase == 'how many') return true;
      }
    }
    return false;
  }

  bool _checkCreateIntent(String query) {
    for (final phrase in _createPhrases) {
      if (_queryStartsWithPhrase(phrase, query)) {
        final queryAfterPhraseStart = query.indexOf(phrase) + phrase.length;
        final remainingQuery = (queryAfterPhraseStart < query.length) ? query.substring(queryAfterPhraseStart).trim() : "";
        if (_objectKeywords.any((obj) => _queryContainsPhrase(obj, remainingQuery) || remainingQuery.startsWith(obj))) {
          return true;
        }
        if (phrase == 'new' && _objectKeywords.any((obj) => remainingQuery.startsWith(obj))) {
            return true;
        }
      }
    }
    final hasGeneralCreateVerb = _generalCreateVerbs.any((verb) => _queryContainsPhrase(verb, query));
    final hasObject = _objectKeywords.any((obj) => _queryContainsPhrase(obj, query));
    if (hasGeneralCreateVerb && hasObject) {
      return true;
    }
    return false;
  }

  bool _checkListIntent(String query) {
    for (final phrase in _listPhrases) {
      if (_queryStartsWithPhrase(phrase, query)) {
        final queryAfterPhraseStart = query.indexOf(phrase) + phrase.length;
        final remainingQuery = (queryAfterPhraseStart < query.length) ? query.substring(queryAfterPhraseStart).trim() : "";
        final isShortCommand = remainingQuery.isEmpty;
        final followedByObject = _objectKeywords.any((obj) => _queryContainsPhrase(obj, remainingQuery) || remainingQuery.startsWith(obj));
        final followedByContextKeyword = _listQueryContextKeywords.any((kw) => remainingQuery.startsWith(kw));
        if (isShortCommand || followedByObject || followedByContextKeyword) {
          return true;
        }
      }
    }
    if (_queryContainsPhrase('list', query)) {
        final hasRelevantObject = _objectKeywords.any((obj) => _queryContainsPhrase(obj, query));
        if (hasRelevantObject) {
            return true;
        }
    }
    return false;
  }

  NlpIntent recognize(String lowerCaseQuery) {
    if (_checkCountIntent(lowerCaseQuery)) {
      return NlpIntent.countTasks;
    }
    if (_checkCreateIntent(lowerCaseQuery)) {
      return NlpIntent.createNote;
    }
    if (_checkListIntent(lowerCaseQuery)) {
      return NlpIntent.listNotes;
    }
    return NlpIntent.unknown;
  }
}