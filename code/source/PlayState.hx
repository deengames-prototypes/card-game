package;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxVelocity;

import flixel.FlxG;

import flixel.plugin.MouseEventManager;

import deengames.combocardgame.Deck;
import deengames.combocardgame.Card;
import deengames.combocardgame.CardView;
import deengames.combocardgame.Combinator;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	static inline var CARD_SCALE:Float = 2/3.0;

	// TODO: a card view also contains the card. This is redundant.
	var firstPickedCard:Card;
	var firstCardView:CardView;

	var secondPickedCard:Card;
	var secondCardView:CardView;

	var comboCard:Card;
	var comboCardView:CardView;

	var combinator = new Combinator();
	var fightButton:FlxButton;
	var yourDeck:Deck;
	var enemyDeck:Deck;

	var cardsInHand:Array<CardView> = new Array<CardView>();

	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		FlxG.debugger.visible = true;
		FlxG.debugger.drawDebug = true;

		this.addAndShow('assets/images/background.png');
		yourDeck = new Deck(20);
		enemyDeck = new Deck(20);

		// Five of yours
		for(n in 0...5) {
			addCardToHand();
		}

		this.fightButton = new FlxButton(16 + 216 + 16 + 216 + 16, 156, 'Fight', fight);
		this.fightButton.loadGraphic('assets/images/button.png');
		this.fightButton.label.setFormat('assets/fonts/OpenSans-Regular.ttf', 48, FlxColor.WHITE);
		add(this.fightButton);
		this.hideFightButton();
	}

	private function makeViewForHand(card:Card) : CardView
	{
		var view = this.makeUiForCard(card, true);

		// Find first blank in hand
		var pos:Int = -1;
		for (n in 0...5) {
			if (cardsInHand[n] == null) {
				pos = n;
				break;
			}
		}
		if (pos == -1) {
			throw "Can't find empty position in deck to put card: #{card}";
		}

		cardsInHand[pos] = view;

		view.index = pos;
		view.sprites.x = (pos * view.sprites.width * CARD_SCALE) + ((pos + 1) * 16);
		view.sprites.y = Main.virtualHeight - (view.sprites.height * CARD_SCALE) - 32;
		addClickEvent(view.sprite, function(sprite) {
			showPicked(card);
		});

		return view;
	}

	// TODO: helperify
	private function addClickEvent(sprite:FlxSprite, callback:FlxSprite->Void) : Void
	{
		MouseEventManager.add(sprite, callback);
	}

	private function showPicked(card:Card) : Void
	{
		if (firstPickedCard != null && secondPickedCard != null) {
			return;
		}

		var view:CardView = null;

		// No cards picked, or only second card picked
		if (firstPickedCard == null && (secondPickedCard == null || secondPickedCard != card)) {
			firstPickedCard = card;
			view = makeUiForCard(firstPickedCard, false);
			view.sprites.x = 16;
			view.sprites.y = 16;
			firstCardView = view;
		// Only first card picked
		} else if (secondPickedCard == null && card != firstPickedCard) {
			secondPickedCard = card;
			view = makeUiForCard(secondPickedCard, false);
			view.sprites.x = 32 + view.sprites.width;
			view.sprites.y = 16;
			secondCardView = view;
		}

		// Hide the card from your hand
		var pos:Int = -1;
		for (n in 0...5) {
			if (cardsInHand[n] != null && cardsInHand[n].card == card) {
				pos = n;
				break;
			}
		}
		if (pos == -1) {
			throw "Can't find empty position in deck to remove picked card: #{card}";
		}
		this.cardsInHand[pos].destroy();
		this.cardsInHand[pos] = null;

		if (firstPickedCard != null && secondPickedCard != null) {
			checkForAndShowCombo();
		}

		showOrHideFightButton();

		this.addClickEvent(view.sprite, function(sprite) {
			if (card == firstPickedCard) {
				firstPickedCard = null;
				firstCardView.destroy();
				destroyComboCardView();
			} else if (card == secondPickedCard) {
				secondPickedCard = null;
				secondCardView.destroy();
				destroyComboCardView();
			}
			view.destroy();

			this.makeViewForHand(card); // Put it back in your hand

			showOrHideFightButton();
		});
	}

	private function showOrHideFightButton() : Void
	{
		hideFightButton();

		// Single card or valid combo
		if ((firstPickedCard != null && secondPickedCard == null) ||
		(firstPickedCard == null && secondPickedCard != null) ||
		(comboCard != null)) {
			showFightButton();
		}
	}

	private function destroyComboCardView() : Void
	{
		comboCard = null;
		if (comboCardView != null) {
			comboCardView.destroy();
		}
	}

	private function showFightButton() : Void
	{
		this.fightButton.visible = true;
	}

	private function hideFightButton() : Void
	{
		this.fightButton.visible = false;
	}

	private function addCardToHand() : Void
	{
		var card = yourDeck.dispenseCard();
		if (card != null) {
			// null when you run out of cards
			var view = makeViewForHand(card);
		}
	}

	private function fight() : Void
	{
		this.hideFightButton();
		var selectedCardView = this.comboCardView != null ? this.comboCardView : this.firstCardView;
		this.removeCardViews(selectedCardView);
		selectedCardView.sprites.x = 16;
		selectedCardView.sprites.y = 16;
		//this.showOpponentCard();
		//FlxVelocity.moveTowardsPoint(cardView.sprites, new FlxPoint(960, 16));
		selectedCardView.sprites.velocity.set(100, 0);
		haxe.Timer.delay(function() {
			this.removeCardViews();
		}, 1);
	}

	private function showOpponentCard() : Void
	{
		var card = this.pickOpponentCard();
		var view = makeUiForCard(card, false);
	}

	private function pickOpponentCard() : Card
	{
		var cards = this.enemyDeck.getHand();
		return cards[0];
	}

	private function removeCardViews(exception:CardView = null) : Void
	{
		if (firstCardView != null && (exception == null || exception != firstCardView)) {
			firstCardView.destroy();
			firstPickedCard = null;
			addCardToHand();
		}

		if (secondCardView != null && (exception == null || exception != secondCardView)) {
			secondCardView.destroy();
			secondPickedCard = null;
			addCardToHand();
		}

		if (comboCardView != null && (exception == null || exception != comboCardView)) {
			comboCardView.destroy();
			comboCard = null;
		}
	}

	private function checkForAndShowCombo() : Void
	{
		var result = combinator.getCombo(firstPickedCard.name, secondPickedCard.name);
		if (result.name != "no-combo") {
			comboCard = result;
			comboCardView = makeUiForCard(result, false);
			comboCardView.sprites.x = Main.virtualWidth - 16 - comboCardView.sprites.width;
			comboCardView.sprites.y = 16;
		}
	}

	private function makeUiForCard(card:Card, scaleDown:Bool) : CardView
	{
		var base = addAndShow('assets/images/cards/card-base.png');
		var inhabitant = addAndShow("assets/images/cards/" + card.name + ".png");
		var border = addAndShow('assets/images/cards/card-border.png');

		// The offset is more for multiple digits compared to single digits.
		var aOffset = card.attack <= 9 ? 10 : 0;
		var dOffset = card.defense <= 9 ? 10: 0;
		var scale = scaleDown == true ? CARD_SCALE : 1;
		var textXOffset = scaleDown == false ? 12 : 6;
		var textYOffset = scaleDown == false ? 50 : 66;

		var textY:Int = Math.round((base.height - textYOffset) * scale);
		var attackText = addText(Std.string(card.attack), (aOffset - 12  + textXOffset) * scale, textY);
		var defenseText = addText(Std.string(card.defense), (base.width - 60 + textXOffset) * scale, textY);

		var group = new flixel.group.FlxSpriteGroup(0, 0);
		group.add(base);
		group.add(inhabitant);
		group.add(border);
		group.add(attackText);
		group.add(defenseText);

		if (scaleDown) {
			group.scale.set(CARD_SCALE, CARD_SCALE);
		}

		group.updateHitbox(); // For click detection

		return new CardView(group, base, card);
	}

	private function addAndShow(string:String) : FlxSprite
	{
		var s:FlxSprite = new FlxSprite();
		s.loadGraphic(string);
		add(s);
		return s;
	}

	private function addText(string:String, x:Float, y:Float) : FlxText
	{
		var text = new FlxText(x, y, 0, string);
		text.setFormat("assets/fonts/OpenSans-Bold.ttf", 36, FlxColor.WHITE, "center");
		text.setBorderStyle(FlxText.BORDER_OUTLINE, FlxColor.BLACK, 1);
		add(text);
		return(text);
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		super.update();
	}
}
