Feature: Supply credentials via HTTP authentication

  Background:

    Given a config "http-auth":
      """
      <check-site-script base-url="http://hostname:${port}">
        <timings warning="2" critical="4" timeout="10"/>
        <step name="page">
          <request path="/page" username="USER" password="PASS"/>
          <response/>
        </step>
      </check-site-script>
      """

  Scenario: Username and password are correct
    Given one server which requires username "USER" and password "PASS"
    When check-site is run with config "http-auth"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 0.0s time"
    And the status should be 0

  Scenario: Username and password are incorrect
    Given one server which requires username "USER" and password "SECRET"
    When check-site is run with config "http-auth"
    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 1 hosts found, 1 errors (401), 0.0s time"
    And the status should be 2
