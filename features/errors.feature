Feature: Handle various types of connection error

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

    Given a config "wrong-port":
      """
      <check-site-script base-url="http://hostname:65535">
        <timings warning="2" critical="4" timeout="10"/>
        <step name="page">
          <request path="/path"/>
          <response/>
        </step>
      </check-site-script>
      """

  Scenario: No servers
    When check-site is run with config "default"
    And the message should be "Site CRITICAL: unable to resolve hostname"
    And the status should be 2

  Scenario: Connection refused
    Given one server which responds in 0 seconds
    When check-site is run with config "wrong-port"
    Then the message should be "Site CRITICAL: 1 hosts found, 1 uncontactable"
    And the status should be 2
