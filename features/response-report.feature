Feature: Check for regex in HTTP response

  Background:

    Given a config "report":
      """
      <check-site-script base-url="http://hostname:${port}">
        <timings warning="2" critical="4" timeout="10"/>
        <step name="page">
          <request path="/page"/>
          <response report-error="\[(.+)\]"/>
        </step>
      </check-site-script>
      """

  Scenario: No servers to report

    Given one server which responds with 200 "abc[def]ghi"
    And another server which responds with 500 "abc[]ghi"

    When check-site is run with config "report"

    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 2 hosts found, 1 errors (500), 0.0s time"
    And the status should be 2

  Scenario: One server to report

    Given one server which responds with 200 "abc[def]ghi"
    And another server which responds with 500 "jkl[]mno"
    And another server which responds with 500 "abc[def]ghi"
    And another server which responds with 500 "jkl[mno]pqr"

    When check-site is run with config "report"

    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 4 hosts found, 3 errors (500), 0.0s time, response 'def'"
    And the status should be 2
