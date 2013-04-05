Feature: Check for regex in HTTP response

  Background:

    Given a config "regex":
      """
        <check-site-script base-url="http://hostname:${port}">
          <timings warning="2" critical="4" timeout="10"/>
          <step name="page">
            <request path="/page"/>
            <response body-regex="y+e+s+"/>
          </step>
        </check-site-script>
      """

  Scenario: Body contains regex
    Given one server which responds with "-yes-"
    When check-site is run with config "regex"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 0.0s time"
    And the status should be 0

  Scenario: Body does not contain regex
    Given one server which responds with "-yes-"
    And one server which responds with "-no-"
    When check-site is run with config "regex"
    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 2 hosts found, 1 mismatches, 0.0s time"
    And the status should be 2
