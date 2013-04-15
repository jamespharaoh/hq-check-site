Feature: Handle timeout correctly

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

    Given a config "timeout":
      """
      <check-site-script base-url="http://hostname:${port}">
        <timings warning="2" critical="4" timeout="0"/>
        <step name="page">
          <request path="/page"/>
          <response/>
        </step>
      </check-site-script>
      """

  Scenario: Timeout does not expire
    Given one server which responds in 0 seconds
    When check-site is run with config "default"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 0.0s time | time=0.0s;2.0;4.0;0.0;10.0"
    And the status should be 0

  Scenario: Timeout expires
    Given one server which responds in 0 seconds
    When check-site is run with config "timeout"
    And the message should be "Site CRITICAL: 1 hosts found, 1 uncontactable"
    And the status should be 2
