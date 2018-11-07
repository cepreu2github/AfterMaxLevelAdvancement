class UIScreenListener_AfterMaxLevelAdvancement extends UIScreenListener config(AfterMaxLevelAdvancement);

var public config int BONUS_AP_CHANCE;
var public config int MAXRANK;

event OnInit(UIScreen Screen)
{
	local UIMissionSummary uiMissionSummary;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;

	uiMissionSummary = UIMissionSummary(Screen);
	History = `XCOMHISTORY;

	// If not XCOM won the mission
	if( !uiMissionSummary.BattleData.bLocalPlayerWon || uiMissionSummary.BattleData.bMissionAborted )
	{
		return;
	}
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.IsPlayerControlled() && Unit.IsSoldier())
		{
			// Filter by soldiers who are at Colonel rank
			if (Unit.GetSoldierRank() >= default.MAXRANK)
			{
				GiveReward(Unit);
			}
		}
	}
}

function GiveReward(XComGameState_Unit PromotedUnit)
{
	local XComGameStateHistory History;
	local XComGameState UpdateState;
	local XComGameState_Unit Unit;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local int BonusAPs;
	local int RandRoll;

	RandRoll = `SYNC_RAND_STATIC(100);
	if (RandRoll >= default.BONUS_AP_CHANCE)
	{
		return;
	}

	BonusAPs = GetBaseSoldierAPAmount(PromotedUnit);

	History = `XCOMHISTORY;
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static
		.CreateEmptyChangeContainer("Bonus Stats at AMLA");
	UpdateState = History.CreateNewGameState(true, ChangeContainer);
	Unit = XComGameState_Unit(
		UpdateState.ModifyStateObject(class'XComGameState_Unit', PromotedUnit.ObjectID)
	);

	Unit.AbilityPoints += BonusAPs;

	`GAMERULES.SubmitGameState(UpdateState);

}	

private function int GetBaseSoldierAPAmount(XComGameState_Unit Unit)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local int APReward;

	// Base game soldier classes gain a lot less AP than other soldiers
	APReward += Unit.GetSoldierClassTemplate().BaseAbilityPointsPerPromotion; // Always start with base points
	if (APReward > 0)
	{
		// Only give AP reward bonus if the soldier class has a base AP gain per promotion
		APReward += class'X2StrategyGameRulesetDataStructures'.default.BaseSoldierComIntBonuses[Unit.ComInt];

		// AP amount could be modified by Resistance Orders
		History = `XCOMHISTORY;
		ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

		if(ResHQ.AbilityPointScalar > 0)
		{
			APReward = Round(float(APReward) * ResHQ.AbilityPointScalar);
		}
	}

	return APReward;
}

defaultProperties
{
	// Set the screen that the Event at the top of this file is listening for
	ScreenClass = UIMissionSummary
}