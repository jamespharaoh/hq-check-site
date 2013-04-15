Feature: Return ok/warning/critical based on response time

  Background:

    Given a config "default":
      """
      <check-site-script base-url="http://hostname:${port}">
        <timings warning="2" critical="4" timeout="10"/>
        <step name="page">
          <request path="/page"/>
          <response/>
        </step>
      </check-site-script>
      """

  Scenario: Site responds in ok time
    Given one server which responds in 1 second
    When check-site is run with config "default"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 1.0s time | time=1.0s;2.0;4.0;0.0;10.0"
    And the status should be 0

  Scenario: Site responds in warning time
    Given one server which responds in 1 second
    And one server which responds in 3 seconds
    When check-site is run with config "default"
    Then all servers should receive page requests
    And the message should be "Site WARNING: 2 hosts found, 3.0s time (warning is 2.0) | time=3.0s;2.0;4.0;0.0;10.0"
    And the status should be 1

  Scenario: Site responds in critical time
    Given one server which responds in 1 second
    And one server which responds in 3 seconds
    And one server which responds in 5 seconds
    When check-site is run with config "default"
    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 3 hosts found, 5.0s time (critical is 4.0) | time=5.0s;2.0;4.0;0.0;10.0"
    And the status should be 2
