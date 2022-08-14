#include openCJ\util;

onPlayerConnected()
{
	self thread _tryLogin();
}

onPlayerCommand(args)
{
	return self openCJ\loginHelper::onPlayerCommand(args);
}

isLoggedIn()
{
	return isDefined(self.login_playerID);
}

getPlayerID()
{
	return self.login_playerID;
}

_tryLogin()
{
	self endon("disconnect");

	uid = self openCJ\loginHelper::requestUID();

	if(!isDefined(uid) || uid.size != 4)
		self createNewAccount();
	else
		self validateLogin(uid);
}

validateLogin(uid)
{
	self endon("disconnect");

	rows = self openCJ\mySQL::mysqlAsyncQuery("SELECT getPlayerID(" + int(uid[0]) + ", " + int(uid[1])  + ", " + int(uid[2]) + ", " + int(uid[3]) + ", '" + openCJ\mySQL::escapeString(self.name) + "')");

	printf("Trying login\n");

	if(!rows.size || !isDefined(rows[0][0]))
	{
		printf("invalid login\n");
		self createNewAccount();
	}
	else
	{
		printf("valid login\n");
		self.login_playerID = int(rows[0][0]);
		self openCJ\events\playerLogin::main();
		//self openCJ\menus::openIngameMenu();
	}
}

createNewAccount()
{
	self endon("disconnect");

	printf("creating login\n");
	for(i = 0; i < 10; i++)
	{
		printf("creating loop login\n");
		uid = [];
		for(j = 0; j < 4; j++)
			uid[j] = createRandomInt();

		rows = self openCJ\mySQL::mysqlAsyncQuery("SELECT createNewAccount(" + uid[0] + ", " + uid[1] + ", " + uid[2] + ", " + uid[3] + ")");
		if(rows.size && isDefined(rows[0][0]))
		{
			printf("creating done login\n");
			self.login_playerID = rows[0][0];
			self openCJ\loginHelper::storeUID(uid);
			self openCJ\events\playerLogin::main();
			return;
		}
		else
			printf("creating acc failed\n");
	}
	self iprintlnbold("Cannot create an account right now. Please try reconnecting");
}