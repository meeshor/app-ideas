import Foundation

/// Kierunek ręki w chwili puszczenia względem pozy „ready”.
///
/// - **pitch** liczymy z wektora grawitacji (w układzie urządzenia), więc nie zależy od
///   konwencji kwaternionu: wzniesienie osi dłoni teraz minus wzniesienie w „ready”.
/// - **yaw** liczymy z obrotu względnego `ready → teraz` (`Quaternion.relative(to:)`),
///   rzutowanego na płaszczyznę poziomą wyznaczoną przez grawitację w „ready”.
///   Dodatni = w prawo, dla obu rąk (płaszczyzna świata, nie nadgarstka).
public enum ThrowGeometry {
    /// Wzniesienie osi `axis` nad poziom, rad (−π/2…π/2), z grawitacji w układzie urządzenia.
    public static func elevation(of axis: Vector3, gravity: Vector3) -> Double {
        let up = -gravity.normalized
        return asin(max(-1, min(1, axis.normalized.dot(up))))
    }

    /// Kąt w poziomie między osią dłoni w „ready” a w chwili `attitude`, rad; dodatni = w prawo.
    ///
    /// „Przód” = pozioma składowa osi dłoni w „ready”. Gdy przedramię jest prawie pionowe
    /// (rzut nad głową), bierzemy `fallbackForward` (oś urządzenia, np. −z: tarcza zegarka
    /// zwrócona do gracza, gdy dłoń jest otwarta do przodu). Bez niej zwracamy 0.
    public static func yaw(
        axis: Vector3,
        readyAttitude: Quaternion,
        readyGravity: Vector3,
        attitude: Quaternion,
        fallbackForward: Vector3? = nil
    ) -> Double {
        let up = -readyGravity.normalized
        let h0 = axis.normalized
        var forward = horizontal(h0, up: up)
        if forward.length <= 0.2, let fallbackForward {
            forward = horizontal(fallbackForward.normalized, up: up)
        }
        guard forward.length > 0.2 else { return 0 }
        let f = forward.normalized
        let right = f.cross(up)
        let now = attitude.relative(to: readyAttitude).act(on: h0)
        let nowHorizontal = horizontal(now, up: up)
        guard nowHorizontal.length > 1e-6 else { return 0 }
        return atan2(nowHorizontal.dot(right), nowHorizontal.dot(f))
    }

    /// Składowa pozioma wektora (rzut na płaszczyznę prostopadłą do `up`).
    static func horizontal(_ v: Vector3, up: Vector3) -> Vector3 {
        v - up * v.dot(up)
    }
}
