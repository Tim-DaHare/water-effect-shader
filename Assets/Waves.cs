using UnityEngine;

[ExecuteInEditMode]
public class Waves : MonoBehaviour
{
    public float width = 100;
    public float length = 100;
    public float tesselationFactor = 50;
    
    private MeshFilter _meshFilter;
    [SerializeField] private Material _waterMaterial;
    
    private static readonly int TesselationFactor = Shader.PropertyToID("_TesselationFactor");

    public void Start()
    {
        _meshFilter = gameObject.GetComponent<MeshFilter>();
    }

    private void Update()
    {
        _waterMaterial.SetFloat(TesselationFactor, tesselationFactor);
        
        Mesh mesh = new Mesh();

        Vector3[] vertices = {
            new Vector3(0, 0, 0),
            new Vector3(width, 0, 0),
            new Vector3(0, 0, length),
            new Vector3(width, 0, length)
        };
        mesh.vertices = vertices;

        var tris = new[]
        {
            // lower left triangle
            0, 2, 1,
            // upper right triangle
            2, 3, 1
        };
        mesh.triangles = tris;

        Vector3[] normals = {
            Vector3.up,
            Vector3.up,            
            Vector3.up,
            Vector3.up,        
        };
        mesh.normals = normals;

        Vector2[] uv = {
            new Vector2(0, 0),
            new Vector2(1, 0),
            new Vector2(0, 1),
            new Vector2(1, 1)
        };
        mesh.uv = uv;

        _meshFilter.mesh = mesh;

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Application.Quit();
        }
    }
}
