Feature: Function correctly in edge cases based on config file

  Background:

    Given a config "no-path":
      """
        <check-site-script base-url="http://hostname:${port}/page">
          <timings warning="2" critical="4" timeout="10"/>
          <step name="page">
            <request/>
            <response/>
          </step>
        </check-site-script>
      """

  Scenario: No path specified
    Given one server which responds in 0 seconds
    When check-site is run with config "no-path"
    Then all servers should receive page requests
    And the message should be "Site OK: 1 hosts found, 0.0s time"
    And the status should be 0
