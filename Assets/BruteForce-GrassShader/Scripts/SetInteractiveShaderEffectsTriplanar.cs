using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetInteractiveShaderEffectsTriplanar : MonoBehaviour
{
    public RenderTexture rt;
    public string GlobalTexName = "_GlobalEffectRT";
    public Vector3 VectorSpace;
    public Transform target;
    public bool isMain = false;
    private void Awake()
    {
        Shader.SetGlobalTexture(GlobalTexName, rt);
        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize);
    }

    private void Update()
    {
        transform.position = target.position + VectorSpace * 20;
        if(isMain)
        Shader.SetGlobalVector("_Position", target.position);
    }
}