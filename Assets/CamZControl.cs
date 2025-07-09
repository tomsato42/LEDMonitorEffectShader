using UnityEngine;

public class CamZControl : MonoBehaviour
{
    [SerializeField] private Vector3 direction = Vector3.forward;
    [SerializeField] private float duration = 2.0f;
    [SerializeField] private AnimationCurve curve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    private Vector3 _startPos;
    private Vector3 _endPos;
    private float _timer;

    private void Start()
    {
        _startPos = transform.position;
        _endPos = _startPos + direction;
        _timer = 0f;
    }

    void Update()
    {
        if (duration <= 0f) return;

        _timer += Time.deltaTime;
        var t = Mathf.PingPong(_timer / duration, 1f);
        var curvedT = curve.Evaluate(t);
        transform.position = Vector3.Lerp(_startPos, _endPos, curvedT);
    }
}