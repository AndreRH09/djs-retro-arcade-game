# Referencia del curso de fútbol

Las mecánicas de los capítulos 4–8 y los fotogramas de las animaciones de golpeo
se adaptaron tomando como referencia **Create a Soccer Game in Godot!**, de
The GameDev Tavern / Nicolas Bize.

- Código de referencia: https://github.com/nicolasbize/soccer-course/tree/v0.0.9
- Licencia original: https://github.com/nicolasbize/soccer-course/blob/v0.0.9/LICENSE

La altura baja del disparo, la amortiguación de los rebotes, el contacto de las
entradas y la composición de las porterías también se contrastaron con
[`v0.2.4`](https://github.com/nicolasbize/soccer-course/tree/v0.2.4), commit
`32dfe726466c1c799a429b8a121d3be04f3a3615`. Los archivos de referencia son
`scenes/ball/ball_states/ball_state.gd`, `ball_state_shot.gd`, los estados
`player_state_tackling.gd` / `player_state_hurt.gd` y `scenes/goal/goal.tscn`.
Las imágenes originales `goal-top.png` y `goal-bottom.png` se reutilizan con la
geometría del partido. La integración mantiene nuestros componentes de IA y la
física compartida con la predicción. Esta versión también usa la licencia MIT.

## MIT License

Copyright (c) 2025 Nicolas Bize

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
