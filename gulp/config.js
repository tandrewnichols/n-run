module.exports = {

  tests: {
    unit: ['test/unit/**/*.coffee', '!test/unit/helpers/**/*.coffee'],
    integration: ['test/integration/**/*.coffee']
  },
  helpers: ['test/unit/helpers/**/*.coffee'],

  lib: ['lib/**/*.js']
};
