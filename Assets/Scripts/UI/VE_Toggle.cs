using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VE_Toggle : MonoBehaviour
{
    public GameObject VE;
    // Start is called before the first frame update
    void Start()
    {
        VE.SetActive(true);
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.V))
        {
            if (VE.activeSelf == true)
            {
                VE.SetActive(false);
            }
            else
            {
                VE.SetActive(true);
            }
        }
    }
}
