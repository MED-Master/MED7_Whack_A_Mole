using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FxOnMouseClick : MonoBehaviour
{
    private Camera mainCam;
    public ParticleSystem ps;
    // Start is called before the first frame update
    void Start()
    {
        mainCam = this.GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            RaycastHit hit;
            Ray ray = mainCam.ScreenPointToRay(Input.mousePosition);
            Debug.DrawRay(this.transform.position, ray.direction);
            if (Physics.Raycast(ray, out hit,100))
            {
                if (!ps.isEmitting)
                {
                    ps.Play();
                }
                ps.transform.position = hit.point;
            }
            else
            {
               // ps.Stop();
            }
        }
        else
        {
            ps.Stop();
        }
    }
}
