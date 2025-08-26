/* functions/.eslintrc.js */
module.exports = {
  root: true,
  env: {
    node: true,
    es6: true,
  },
  extends: ['eslint:recommended', 'google'],
  parserOptions: {ecmaVersion: 2021},
  rules: {
    // Keep jsdoc optional.
    'require-jsdoc': 'off',

    // Allow long lines for URLs/strings/templates/comments.
    'max-len': [
      'error',
      {
        code: 120,
        tabWidth: 2,
        ignoreUrls: true,
        ignoreStrings: true,
        ignoreTemplateLiterals: true,
        ignoreComments: true,
      },
    ],

    // Relax a few style nits that were noisy with Firebase + Google config.
    'block-spacing': ['error', 'always'],
    'brace-style': ['error', '1tbs', {allowSingleLine: true}],
    'quote-props': ['error', 'consistent-as-needed'],
  },
};
