Feature: Log in via an HTML form

  Background:

    Given a config "form-auth":
      """
        <check-site-script base-url="http://hostname:${port}">
          <timings warning="2" critical="4" timeout="10"/>
          <step name="login">
            <request path="/login" method="post">
              <param name="username" value="USER"/>
              <param name="password" value="PASS"/>
            </request>
            <response/>
          </step>
          <step name="page">
            <request path="/page" username="USER" password="PASS"/>
            <response/>
          </step>
        </check-site-script>
      """

  Scenario: Form based login
    Given one server which requires form based login with "USER" and "PASS"
     When check-site is run with config "form-auth"
     Then all servers should receive page requests
      And the message should be "Site OK: 1 hosts found, 0.0s time"
      And the status should be 0
