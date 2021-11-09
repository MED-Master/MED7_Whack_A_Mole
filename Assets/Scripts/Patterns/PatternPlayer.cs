using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System;

/*
Class dedicated to play the pattern at runtime from the dictionary given by the pattern parser.
Calls the PatternInterface to call the different elements and translate the dictionary into concrete actions;
*/

public class PatternPlayer : MonoBehaviour
{
    private Dictionary<float, List<Dictionary<string, string>>> pattern = new Dictionary<float, List<Dictionary<string, string>>>();
    private List<float> sortedKeys = new List<float>();
    private List<int> listMoleId = new List<int>();
    private Dictionary<int, Mole> tempMolesList = new Dictionary<int, Mole>();
    private float waitTimeLeft = 0f;
    private float waitForDuration = -1f;
    private int playIndex = 0;
    private int Id = 1;
    private bool isRunning = false;
    private bool isPaused = false;
    private PatternInterface patternInterface;
    private WallManager wallManager;
    private PatternParser patternParser;

    void Awake()
    {
        patternInterface = FindObjectOfType<PatternInterface>();
        wallManager = FindObjectOfType<WallManager>();
        patternParser = new PatternParser();
    }

    void Update()
    {
        if (patternParser.GetParadigm() == PatternParser.Paradigm.Progression)
        {
            ProgressionParadigm();
        }

        // Check whether we need to wait.
        if (waitForDuration == -1f) return;

        // if our wait time is 0, we initialize it.
        if (waitTimeLeft == 0f) waitTimeLeft = waitForDuration;

        // if wait time is above 0, we wait.
        // if wait time is below 0, wait time is over.
        if (waitTimeLeft > 0)
        {
            if (!isPaused) waitTimeLeft -= Time.deltaTime;
        }
        else
        {
            waitForDuration = -1f;
            waitTimeLeft = 0f;
            PlayStep();
        }
    }

    // Plays the loaded pattern if one is actually loaded.
    public void PlayPattern()
    {
        if (isRunning) return;
        if (sortedKeys.Count == 0) return;
        isRunning = true;
        isPaused = false;

        if (sortedKeys[0] == 0f) PlayStep();
        else waitForDuration = sortedKeys[0];
    }

    // Stops the pattern play if it is currently playing.
    public void StopPatternPlay()
    {
        if (!isRunning) return;
        isRunning = false;
        ResetPlay();
    }

    // Pauses/unpauses the pattern play if it is currently playing.
    public void PauseUnpausePattern(bool pause)
    {
        if (isPaused == pause) return;
        isPaused = pause;
    }

    // Returns if it is currently playing a pattern or not.
    public bool IsPlaying()
    {
        return isRunning;
    }

    // Returns the duration of the currently loaded pattern.
    public float GetPatternDuration()
    {
        return sortedKeys.Max();
    }

    // Loads a pattern
    public void SetPattern(Dictionary<float, List<Dictionary<string, string>>> newPattern)
    {
        if (newPattern.Count == 0) return;
        pattern = newPattern;
        sortedKeys = pattern.Keys.ToList();
        sortedKeys.Sort();
    }

    // Unloads the loaded pattern.
    public void ClearPattern()
    {
        if (isRunning) StopPatternPlay();
        pattern.Clear();
        sortedKeys.Clear();
    }

    // Resets the state of pattern play (so it can be played again).
    private void ResetPlay()
    {
        waitForDuration = -1f;
        playIndex = 0;
        waitTimeLeft = 0f;
        Id = 1;
        tempMolesList.Clear();
    }

    // Returns the time to wait before playing the next action when the loaded pattern is playing.
    private float GetWaitTime(int index)
    {
        if (index >= sortedKeys.Count - 1) return 0f;
        else return sortedKeys[index + 1] - sortedKeys[index];
    }

    // Plays a step from the pattern and triggers the wait to play the next step (if the current step isn't the last).
    private void PlayStep()
    {
        wallManager.SetSpawnOrder(playIndex);

        foreach (Dictionary<string, string> action in pattern[sortedKeys[playIndex]])
        {
            patternInterface.PlayAction(new Dictionary<string, string>(action));
            listMoleId = patternInterface.GetListMoleId();
        }

        foreach (var moleCoord in listMoleId)
        {
            var moles = wallManager.GetMoles();
            Mole mole = moles[moleCoord];
            var spawnOrder = mole.GetSpawnOrder();

            if (spawnOrder == playIndex)
            {
                int moleId = Convert.ToInt32(string.Format("{0}{1}", Id, moleCoord));
                tempMolesList.Add(moleId, mole);
                Id++;
            }
        }

        if (playIndex < sortedKeys.Count - 1)
        {
            playIndex++;
            waitForDuration = GetWaitTime(playIndex - 1);
        }
    }

    //Check if the pattern is a progression paradigm
    public void ProgressionParadigm()
    {
        var moles = wallManager.GetMoles();
        int moleCount = patternParser.GetMoleCount();

        foreach (var mole in moles.Values)
        {
            var moleState = mole.GetState();

            if (moleState == Mole.States.Enabled && !mole.GetFake())
            {
                return;
            }
        }

        foreach (var mole in tempMolesList.Values)
        {
            var moleState = mole.GetState();
            var spawnOrder = mole.GetSpawnOrder();

            if (moleState == Mole.States.Popping || moleState == Mole.States.Disabling)
            {
                foreach (var fake in tempMolesList.Where(fake => fake.Value.GetFake() && fake.Value.GetState() == Mole.States.Enabled))
                {
                    fake.Value.Disable();
                }
                mole.Disable();
                waitForDuration = -1f;
                waitTimeLeft = 0f;
                PlayStep();
            }

            if ((playIndex == sortedKeys.Count && moleState == Mole.States.Popped) || (playIndex == sortedKeys.Count - 1 && moleState == Mole.States.Expired))
            {
                patternInterface.CallStop();
            }
        }
    }
}