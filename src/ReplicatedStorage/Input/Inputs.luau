local Inputs = {
	
	Actions = {
		
		Interact = {
			PC = Enum.KeyCode.E,
			Console = Enum.KeyCode.ButtonX
		},
        
		Inventory = {
			PC = {
				Slot1 = Enum.KeyCode.One,
				Slot2 = Enum.KeyCode.Two,
				Slot3 = Enum.KeyCode.Three,
				Slot4 = Enum.KeyCode.Four,
				Slot5 = Enum.KeyCode.Five,
				Slot6 = Enum.KeyCode.Six,
				Slot7 = Enum.KeyCode.Seven,
				Slot8 = Enum.KeyCode.Eight,
				Slot9 = Enum.KeyCode.Nine,
				Slot10 = Enum.KeyCode.Zero
			},
			Console = {
				NextSlot = Enum.KeyCode.ButtonR1,
				PreviousSlot = Enum.KeyCode.ButtonL1,
			}
		}
	},

	Axis = {
		HeadTurn = {
			PC = Enum.KeyCode.Z,
			Console = Enum.KeyCode.ButtonL3
		}
	}
}

return Inputs