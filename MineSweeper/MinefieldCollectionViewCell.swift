import UIKit

class MinefieldCollectionViewCell: UICollectionViewCell {

    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	internal func configureCell(forCellState cellState: Minefield.CellState) {
		// Encapsulate view details and configure based on the model, cellState.
		// Opened squares should have a `UIColor.darkGray` background, while closed squares should remain `UIColor.black`.
		backgroundColor = UIColor.darkGray
		var text = "?"

		switch cellState {
		case .closed:
			backgroundColor = UIColor.black
			break
		case .flagged:
			text = "🚩"
			break
		case .opened(let count):
			// If an opened square is adjacent to any mines, the number of mines in adjacent squares is displayed in the square.
			// If the number is 0, omit the number. Diagonals are considered adjacent.
			if count == Minefield.daBomb {
				text = "💣"
				backgroundColor = UIColor.red
			} else if count == 0 {
				text = ""
			} else {
				text = String(count)
			}
			break
		}

        label.text = text
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
	}
}
