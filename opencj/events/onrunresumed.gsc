// Resuming a run is done when the 'cheating' status is removed, typically by loading back
main()
{
    self openCJ\huds\hudRunInfo::onRunResumed();
    self openCJ\huds\hudProgressBar::onRunResumed();
    self openCJ\elevate::onRunResumed();
    // Recheck FPS changed while mode detection was paused.
    self openCJ\fps::onSpawnPlayer();
}