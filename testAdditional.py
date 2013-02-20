import os
import unittest
import json
from httplib import HTTPConnection

SERVER = "fast-fortress-6544.herokuapp.com"

class RestTestCase(unittest.TestCase):
    """Super class for each scenario"""
    SUCCESS             =  1     #: a success
    ERR_BAD_CREDENTIALS = -1     #: (for login only) cannot find the user/password pair in the database
    ERR_USER_EXISTS     = -2     #: (for add only) trying to add a user that already exists
    ERR_BAD_USERNAME    = -3     #: (for add, or login) invalid user name (only empty string is invalid for now)
    ERR_BAD_PASSWORD    = -4     #: (for add only) invalid password (longer than 128 chars)

    def setUp(self):
        self.conn = HTTPConnection(SERVER, timeout=1)
        self.makeRequest("/TESTAPI/resetFixture")
        
    def makeRequest(self, url, method="POST", data={ }):
        """
        Make a request to the server.
        @param url is the relative url (no hostname)
        @param method is either "GET" or "POST"
        @param data is an optional dictionary of data to be send using JSON
        @result is a dictionary of key-value pairs
        """
        
        headers = { "Content-Type": "application/json", "Accept": "application/json" }
        body = json.dumps(data) if data != None else ""

        try:
            self.conn.request(method, url, body, headers)
        except Exception, e:
            if str(e).find("Connection refused") >= 0:
                print "Cannot connect to the server "+RestTestCase.serverToTest+". You should start the server first, or pass the proper TEST_SERVER environment variable"
                sys.exit(1)
            raise

        self.conn.sock.settimeout(100.0) # Give time to the remote server to start and respond
        resp = self.conn.getresponse()
        data_string = "<unknown"
        try:
            self.assertEquals(200, resp.status)
            data_string = resp.read()
            # The response must be a JSON request
            # Note: Python (at least) nicely tacks UTF8 information on this,
            #   we need to tease apart the two pieces.
            self.assertIsNotNone(resp.getheader('content-type'), "content-type header must be present in the response")
            self.assertTrue(resp.getheader('content-type').find('application/json') == 0, "content-type header must be application/json")

            data = json.loads(data_string)
            return data
        except:
            # In case of errors dump the whole response,to simplify debugging
            print "Got exception when processing response to url="+url+" method="+method+" data="+str(data)
            print "  Response status = "+str(resp.status)
            print "  Resonse headers: "
            for h, hv in resp.getheaders():
                print "    "+h+"  =  "+hv
            print "  Data string: "+data_string
            raise

    def assertResponse(self, response, errCode, count=None):
        expected = {'errCode': errCode}
        if count != None:
            expected['count'] = count
        self.assertDictEqual(expected, response)

    def tearDown(self):
        self.conn.close()

class TestUnit(RestTestCase):
    """Issue a REST API request to run the unit tests, and analyze the result"""
    def testUnit(self):
        respData = self.makeRequest("/TESTAPI/unitTests", method="POST")
        self.assertTrue('output' in respData)
        print ("Unit tests output:\n"+
               "\n***** ".join(respData['output'].split("\n")))
        self.assertTrue('totalTests' in respData)
        print "***** Reported "+str(respData['totalTests'])+" unit tests"
        # When we test the actual project, we require at least 10 unit tests
        minimumTests = 10
        if "SAMPLE_APP" in os.environ:
            minimumTests = 4
        self.assertTrue(respData['totalTests'] >= minimumTests,
                        "at least "+str(minimumTests)+" unit tests. Found only "+str(respData['totalTests'])+". use SAMPLE_APP=1 if this is the sample app")
        self.assertEquals(0, int(respData['nrFailed']))


        
class TestAddUser(RestTestCase):
    """Test adding users"""

    def test1(self):
        #Test for a valid user signup with a count of 1
        response = self.makeRequest("/users/add", data={'username':'jackyng', 'password':'foobar'})
        self.assertResponse(response, RestTestCase.SUCCESS, 1)

    def test2(self):
        #Test for ERR_USER_EXISTS
        response = self.makeRequest("/users/add", data={'username':'gundam', 'password':'wing'})
        response = self.makeRequest("/users/add", data={'username':'gundam', 'password':'wing'})
        self.assertResponse(response, RestTestCase.ERR_USER_EXISTS)

    def test3(self):
        #Test for ERR_BAD_USERNAME (empty username)
        response = self.makeRequest("/users/add", data={'username':'', 'password':'ohai'})
        self.assertResponse(response, RestTestCase.ERR_BAD_USERNAME)

    def test4(self):
        #Test for ERR_BAD_USERNAME (an username that is longer than 128 characters)
        response = self.makeRequest("/users/add", data={'username':'n'*150, 'password':'epyon'})
        self.assertResponse(response, RestTestCase.ERR_BAD_USERNAME)

    def test5(self):
        #Test for ERR_BAD_PASSWORD
        response = self.makeRequest("/users/add", data={'username':'zeon', 'password':'g'*150})
        self.assertResponse(response, RestTestCase.ERR_BAD_PASSWORD)

class TestLoginUser(RestTestCase):
    """Test logging in users"""

    def test6(self):
        #Test for successful login with valid credentials
        response = self.makeRequest("/users/add", data={'username':'jackyng', 'password':'foobar'})
        for i in range(1,25):
            response = self.makeRequest("/users/login", data={'username':'jackyng', 'password':'foobar'})
            self.assertResponse(response, RestTestCase.SUCCESS, count=i+1)

    def test7(self):
        #Test for ERR_BAD_CREDENTIALS (no valid username)
        response = self.makeRequest("/users/login", data={'user':'teehee', 'password':'troll'})

    def test8(self):
        #Test for ERR_BAD_CREDENTIALS (wrong password)
        response = self.makeRequest("/users/add", data={'user':'holy', 'password':'arrow'})
        response = self.makeRequest("/users/login", data={'user':'holy', 'password':'grenade'})
        self.assertResponse(response, RestTestCase.ERR_BAD_CREDENTIALS)
