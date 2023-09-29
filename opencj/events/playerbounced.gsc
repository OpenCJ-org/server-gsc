#include openCJ\util;

main(time)
{
    self.bounceTime = time;
    self openCJ\measurements::RPGMeasurement(false, time);

    self openCJ\huds\hudFpsHistory::onBounced();
    self openCJ\events\eventHandler::onBounced();
    self openCJ\measurements::onBounced();
}