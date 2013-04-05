Feature: Authenticate via custom HTTP headers

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

    Given a config "headers-auth":
      """
        <check-site-script base-url="http://hostname:${port}">
          <timings warning="2" critical="4" timeout="10"/>
          <step name="page">
            <request path="/page">
              <header name="username" value="USER"/>
              <header name="password" value="PASS"/>
            </request>
            <response/>
          </step>
        </check-site-script>
      """

  Scenario: Form based login success
    Given one server which requires header based login
    When check-site is run with config "headers-auth"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 0.0s time"
    And the status should be 0

  Scenario: Form based login failure
    Given one server which requires header based login
    When check-site is run with config "default"
    Then all servers should receive page requests
    And the message should be "Site CRITICAL: 1 hosts found, 1 errors (500), 0.0s time"
    And the status should be 2
