﻿using UnityEngine;

public class Centering : MonoBehaviour
{
    [Tooltip("Desired head position of player when seated")]
    public Transform desiredHeadPosition;

    //Assign these variables in the inspector, or find them some other way (eg. in Start() )
    public Transform steamCamera;
    public Transform cameraRig;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            if (desiredHeadPosition != null)
            {
                ResetSeatedPos(desiredHeadPosition);
            }
            else
            {
                Debug.LogError("Target Transform required. Assign in inspector.", gameObject);
            }
        }
    }

    private void ResetSeatedPos(Transform desiredHeadPos)
    {
        if ((steamCamera != null) && (cameraRig != null))
        {
            //ROTATION
            // Get current head heading in scene (y-only, to avoid tilting the floor)
            float offsetAngle = steamCamera.rotation.eulerAngles.y;
            // Now rotate CameraRig in opposite direction to compensate
            cameraRig.Rotate(0f, -offsetAngle, 0f);

            //POSITION
            // Calculate postional offset between CameraRig and Camera
            Vector3 offsetPos = cameraRig.position - steamCamera.position;
            // Reposition CameraRig to desired position minus offset
            cameraRig.position = desiredHeadPos.position;
            offsetPos.y = -offsetPos.y - 0.75f;
            cameraRig.position = offsetPos;
            //cameraRig.position.Set(offsetPos.x, offsetPos.y, offsetPos.z); //offsetPos;
            //cameraRig.position = [offsetPos.x, offsetPos.y, offsetPos.z];

            Debug.Log("Seat recentered!");
        }
        else
        {
            Debug.Log("Error: SteamVR objects not found!");
        }
    }
}