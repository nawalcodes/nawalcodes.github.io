/**
 * Factory Module
 * 
 * This module contains functionality for metaprogramming to generate factories for creating 
 * game objects. The primary function `GameObjectFactory` supports the creation of various game 
 * entities like players, enemies, scores, or coins, and dynamically adds components based on 
 * template parameters.
 * 
 * Reference:
 * https://dlang.org/articles/variadic-function-templates.html
 */
module factory;

import component;
import gameobject;

/**
 * `GameObjectFactory` dynamically creates game objects based on the specified name and optional components.
 * 
 * Params:
 *   T (variadic template parameter) – A list of component types to be added to the game object.
 *   name (string) – The name of the game object to create (e.g., "Player", "Enemy").
 * 
 * Returns:
 *   A `GameObject` with the specified components attached.
 * 
 * Throws:
 *   AssertionError if an unsupported component type is encountered.
 * 
 * Example:
 * ---
 * auto player = GameObjectFactory!("Player", ComponentType.CIRCLE_COLLIDER, ComponentType.TEXTURE);
 * auto enemy = GameObjectFactory!("Enemy");
 * ---
 */
GameObject GameObjectFactory(T...)(string name)
{
	GameObject go;
	if (name == "Player")
		go = new Player();
	else if (name == "Enemy")
		go = new Enemy();
	else if (name == "Score")
		go = new Score();
	else if (name == "Coin") 
		go = new Coin();
	else
		go = new GameObject(name);

	// import std.stdio;
	// writeln(name);
	/// Static foreach loop will be 'unrolled' with each conditional.
	/// This handles the case where we repeat component types as well if our
	/// game object supports multiple components of the same type

	/// Conditional rendering of textures, colliders, lasers and text
	static foreach (component; T)
	{
		static if (component == ComponentType.TEXTURE)
		{
			go.AddComponent!(component)(new ComponentTexture(go.GetID()));
		}
		else if (component == ComponentType.CIRCLE_COLLIDER)
		{
			go.AddComponent!(component)(new ComponentColliderCircle(go.GetID()));
		}
		else if (component == ComponentType.LASER)
		{
			go.AddComponent!(component)(new ComponentLaser(go.GetID()));
		}
		else if (component == ComponentType.TEXT)
		{
			go.AddComponent!(component)(new ComponentText(go.GetID()));
		}
		else
		{
			assert(0, "Did not find right component");
		}
	}
	return go;
}

/**
 * Alias `MakeCircle` simplifies the creation of game objects with a circle collider component.
 */
alias MakeCircle = GameObjectFactory!(ComponentType.CIRCLE_COLLIDER);

/**
 * Alias `MakeLaser` simplifies the creation of game objects with a laser component.
 */
alias MakeLaser = GameObjectFactory!(ComponentType.LASER);

/**
 * Alias `MakePlayer` simplifies the creation of player objects with circle collider and texture components.
 */
alias MakePlayer = GameObjectFactory!(ComponentType.CIRCLE_COLLIDER, ComponentType.TEXTURE);

/**
 * Alias `MakeEnemy` simplifies the creation of enemy objects with circle collider and texture components.
 */
alias MakeEnemy = GameObjectFactory!(ComponentType.CIRCLE_COLLIDER, ComponentType.TEXTURE);

/**
 * Alias `MakeText` simplifies the creation of game objects with a text component.
 */
alias MakeText = GameObjectFactory!(ComponentType.TEXT);

/**
 * Alias `MakeCoin` simplifies the creation of coin objects with circle collider and texture components.
 */
alias MakeCoin = GameObjectFactory!(ComponentType.CIRCLE_COLLIDER, ComponentType.TEXTURE);
