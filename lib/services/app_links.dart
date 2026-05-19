class AppLinks {
  const AppLinks._();

  static const developerName = 'word-hunter';
  static const repositoryOwner = 'word-hunter';
  static const repositoryName = 'flow-read';
  static const repositorySlug = '$repositoryOwner/$repositoryName';

  static final Uri repositoryUrl = Uri.https('github.com', repositorySlug);
  static final Uri releasePageUrl = Uri.https(
    'github.com',
    '$repositorySlug/releases',
  );
  static final Uri issueFeedbackUrl = Uri.https(
    'github.com',
    '$repositorySlug/issues/new',
  );
}
